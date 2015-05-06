'use strict';
var util = require('util');
var EventEmitter = require('events').EventEmitter;
var stableStringify = require('json-stable-stringify');
var _ = require('lodash');
var debug = require('debug')('meshblu:Connection');
var url = require('url');

var DEFAULT_TIMEOUT = 10000;

function Connection(opt, dependencies){

  dependencies = dependencies || {};
  var socketIoClient = dependencies.socketIoClient || require('socket.io-client');
  this.NodeRSA = dependencies.NodeRSA || require('node-rsa');
  this.console = dependencies.console || console;
  this.subscriptions = [];

  opt = _.cloneDeep(opt);

  EventEmitter.call(this);

  this._callbackHandlers = {};
  this._ackId = 0;

  this.options = opt || {};
  this.options.options = this.options.options || {};

  if(this.options.privateKey) {
    this.setPrivateKey(this.options.privateKey);
  }

  this.options.forceNew = (opt.forceNew !== null) ? opt.forceNew : false;

  var socketOptions = _.defaults(
    _.clone(this.options.options),
    {'force new connection': true}
  );

  debug('parsing URL', this.options.server, this.options.port);
  var serverUrl = this.parseUrl(this.options.server, this.options.port) || 'wss://meshblu.octoblu.com';
  debug('serverUrl', serverUrl);
  this.socket = socketIoClient(serverUrl, socketOptions);
  this.setup();
}

util.inherits(Connection, EventEmitter);

Connection.prototype.parseUrl = function(serverUrl, port) {
  if (!serverUrl) {
    return null;
  }

  try {
    port = parseInt(port);
  } catch (e) {
  }

  if (!/:\/\//.test(serverUrl)) {
    serverUrl = 'ws://' + serverUrl;
  }

  var parsedUrl = url.parse(serverUrl);
  parsedUrl.port = port;
  delete parsedUrl.host; // port will not be used unless host is undefined

  if (/^https/.test(parsedUrl.protocol) || port === 443) {
    parsedUrl.protocol = 'wss';
  }

  if (!/^wss?/.test(parsedUrl.protocol)) {
    parsedUrl.protocol = 'ws';
  }

  return parsedUrl.format();
}


Connection.prototype.generateKeyPair = function() {
  var key = new this.NodeRSA();
  key.generateKeyPair();
  return {
    privateKey: key.exportKey('private'),
    publicKey: key.exportKey('public')
  }
}

Connection.prototype.getPublicKey = function(uuid, callback) {
  var self = this;
  this.socket.emit('getPublicKey', uuid, function(error, publicKey) {
    if (error || !publicKey) {
      return callback(new Error('Could not find public key for device'));
    }

    debug('getPublicKey', publicKey);
    callback(null, new self.NodeRSA(publicKey));
  });
}

Connection.prototype.setPrivateKey = function(privateKey) {
  this.privateKey = new this.NodeRSA(privateKey);
};

Connection.prototype.setup = function(){
  var self = this;
  this.socket.once('connect', function(){
    this.emit('connect');

    this.socket.on('messageAck', function(data){
      if(self._callbackHandlers[data.ack]){
        try{
          self._callbackHandlers[data.ack](data.payload);
          delete self._callbackHandlers[data.ack];
        }
        catch(err){
          console.log('error resolving callback', err);
        }
      }
    });

    this.socket.on('message', function(data){
      self._handleAckRequest('message', data);
    });

    this.socket.on('config', function(data){
      self._handleAckRequest('config', data);
    });

    this.socket.on('disconnect', this.emit.bind(this, 'disconnect'));
    this.socket.on('identify', this.identify.bind(this));
    this.socket.on('ready', this._ready.bind(this));
    this.socket.on('notReady', this.emit.bind(this, 'notReady'));
    this.socket.on('tb', this.emit.bind(this, 'tb'));
    this.socket.on('unboundSocket', this.emit.bind(this, 'unboundSocket'));
    this.socket.on('unregistered', this.emit.bind(this, 'unregistered'));

  }.bind(this));

  return this;
};

//Provide callback when message with ack requests comes in from another client
Connection.prototype._handleAckRequest = function(topic, data){
  var self = this;
  if (this.privateKey && data.encryptedPayload) {
    data.decryptedPayload = JSON.parse(this.privateKey.decrypt(data.encryptedPayload));
  }

  if(data){
    if(data.ack && data.fromUuid){
      //TODO clean these up if not used
      self.emit(topic, data, function(response){
        self._messageAck({
          devices: data.fromUuid,
          ack: data.ack,
          payload: response
        });
      });
    }else{
      self.emit(topic, data);
    }
  }
};

//Allow for making RPC requests to other clients
Connection.prototype._emitWithAck = function(topic, data, fn){
  var self = this;
  if(data){
   if(fn){
      var ack = ++this._ackId;
      data.ack = ack;
      self._callbackHandlers[ack] = fn;
      var timeout = data.timeout || DEFAULT_TIMEOUT;
      //remove handlers
      setTimeout(function(){
        if(self._callbackHandlers[ack]){
          self._callbackHandlers[ack]({error: 'timeout ' + timeout});
          delete self._callbackHandlers[ack];
        }
      }, timeout);
    }
    this.socket.emit(topic, data);
  }
  return this;
};

Connection.prototype._messageAck = function(response){
  this.socket.emit('messageAck', response);
  return this;
};

Connection.prototype._ready = function(data){
  var self = this;
  self.options.uuid = data.uuid;
  if(data.token) {
    self.options.token = data.token;
  }

  _.each(self.subscriptions, function(subscription){
    self.socket.emit('subscribe', subscription);
  });

  self.emit('ready', data);
};

Connection.prototype.identify = function(){
  this.socket.emit('identity', {
    uuid: this.options.uuid,
    token: this.options.token,
    protocol: 'websocket'
  });
  return this;
};

Connection.prototype.sign = function(data) {
  return this.privateKey.sign(stableStringify(data)).toString('base64');
};

Connection.prototype.verify = function(message, signature ) {
  return this.privateKey.verify(stableStringify(message) , signature, 'utf8', 'base64');
};


Connection.prototype.encryptMessage = function(uuid, message, options, callback) {
  var self = this;
  if(_.isFunction(options)){
    callback = options;
    options = {};
  }

  self.getPublicKey(uuid, function(error, key){
    if (error) {
      self.console.error("can't find public key for device");
      return;
    }
    var encryptedMessage = {
      encryptedPayload : key.encrypt(stableStringify(message)).toString('base64')
    };
    options = _.defaults(encryptedMessage, options);
    self.message(uuid, null, options, callback);
  });
};

Connection.prototype.message = function(devices, payload, options, callback) {
  if (_.isFunction(options)) {
    callback = options;
  }

  if (_.isObject(devices) && !_.isArray(devices)) {
    callback = payload;
    options  = _.omit(devices, 'payload', 'devices');
    payload  = devices.payload;
    devices  = devices.devices;
  }

  var message = _.extend({devices: devices, payload: payload}, options);

  debug('sending message', message);
  return this._emitWithAck('message', message, callback);
};

Connection.prototype.send = function(text) {

  if(text){
    text = text.toString();
    this.socket.send(text);
  }

  return this;
};

Connection.prototype.update = function(data, fn) {
  this.socket.emit('update', data, fn);
  return this;
};

Connection.prototype.register = function(data, fn) {
  this.socket.emit('register', data, fn);
  return this;
};

Connection.prototype.unregister = function(data, fn) {
  this.socket.emit('unregister', data, fn);
  return this;
};

Connection.prototype.claimdevice = function(data, fn) {
  this.socket.emit('claimdevice', data, fn);
  return this;
};

Connection.prototype.whoami = function(data, fn) {
  this.socket.emit('whoami', data, fn);
  return this;
};

Connection.prototype.device = function(data, fn) {
  this.socket.emit('device', data, fn);
  return this;
};

Connection.prototype.devices = function(data, fn) {
  this.socket.emit('devices', data, fn);
  return this;
};

Connection.prototype.mydevices = function(data, fn) {
  this.socket.emit('mydevices', data, fn);
  return this;
};

Connection.prototype.status = function(data) {
  this.socket.emit('status', data);
  return this;
};

var uuidOrObject = function(data) {
  if(typeof data === 'string'){
    data = {uuid: data};
  }
  return data;
};

Connection.prototype.subscribe = function(data, fn) {
  this.subscriptions = _.reject(this.subscriptions, uuidOrObject(data));
  this.subscriptions.push(uuidOrObject(data));
  this.socket.emit('subscribe', uuidOrObject(data), fn);
  return this;
};

Connection.prototype.unsubscribe = function(data, fn) {
  this.socket.emit('unsubscribe', uuidOrObject(data), fn);
  this.subscriptions = _.reject(this.subscriptions, uuidOrObject(data));
  return this;
};

Connection.prototype.authenticate = function(data, fn) {
  this.socket.emit('authenticate', data, fn);
  return this;
};

Connection.prototype.events = function(data, fn) {
  this.socket.emit('events', data, fn);
  return this;
};

Connection.prototype.data = function(data, fn) {
  this.socket.emit('data', data, fn);
  return this;
};

Connection.prototype.getdata = function(data, fn) {
  this.socket.emit('getdata', data, fn);
  return this;
};

Connection.prototype.localdevices = function(fn) {
  this.socket.emit('localdevices', {}, fn);
  return this;
};

Connection.prototype.unclaimeddevices = function(data, fn) {
  this.socket.emit('unclaimeddevices', data, fn);
  return this;
};

Connection.prototype.textBroadcast = function(data) {
  if(typeof data !== 'string'){
    data = String(data);
  }
  this.socket.emit('tb', data);
  return this;
};

Connection.prototype.directText = function(data) {
  if(typeof data === 'object' && data.payload && typeof data.payload === 'string' && data.devices){
    this.socket.emit('directText', data);
  }
  else{
    console.log('directText requires an object with a string payload property, and a devices property');
  }

  return this;
};

Connection.prototype.subscribeText = function(data, fn) {
  this.socket.emit('subscribeText', uuidOrObject(data), fn);
  return this;
};

Connection.prototype.unsubscribeText = function(data, fn) {
  this.socket.emit('unsubscribeText', uuidOrObject(data), fn);
  return this;
};

Connection.prototype.close = function(fn){
  this.socket.close(fn);
  return this;
};

Connection.prototype.resetToken = function(data, fn){
  this.socket.emit('resetToken', uuidOrObject(data), fn);
};

Connection.prototype.generateAndStoreToken = function(data, fn){
  this.socket.emit('generateAndStoreToken', data, fn);
};

module.exports = Connection;
