'use strict';
var _ = require('lodash');
var url = require('url');
var util = require('util');
var Backoff  = require('backo');
var backoff = new Backoff({min: 1000, max: 60 * 60 * 1000});
var debug = require('debug')('meshblu:Connection');
var EventEmitter = require('events').EventEmitter;
var stableStringify = require('json-stable-stringify');
var socketIoClient;
var timeout;

var DEFAULT_TIMEOUT = 10000;
var DEFAULT_BUFFER_RATE = 100;
var DEFAULT_CONNECTION_TIMEOUT = 30000;
var DEFAULT_MESHBLU_URI = 'wss://meshblu.octoblu.com';

function Connection(opt, dependencies){

  dependencies = dependencies || {};
  socketIoClient = dependencies.socketIoClient || require('socket.io-client');
  this.NodeRSA = dependencies.NodeRSA || require('node-rsa');
  this.console = dependencies.console || console;
  this.subscriptions = [];
  this._emitStack = [];

  var bufferRate = opt.bufferRate;
  if (_.isNull(bufferRate) || _.isUndefined(bufferRate)) {
    bufferRate = DEFAULT_BUFFER_RATE;
  }
  var connectionTimeout = opt.connectionTimeout
  if (_.isNull(connectionTimeout) || _.isUndefined(connectionTimeout)) {
    connectionTimeout = DEFAULT_CONNECTION_TIMEOUT;
  }

  this._processEmitStack = _.bind(this._processEmitStack, this);
  this._throttledProcessEmitStack = _.bind(_.throttle(this._processEmitStack, bufferRate), this);

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

  this.connectionTimeout = connectionTimeout;
  this.connect();
}

util.inherits(Connection, EventEmitter);

Connection.prototype._processEmitStack = function(){
  if(_.isEmpty(this._emitStack)){ return; }

  var args = this._emitStack.shift();
  this.socket.emit.apply(this.socket, args);

  _.defer(this._throttledProcessEmitStack)
};

Connection.prototype.bufferedSocketEmit = function(){
  this._emitStack.push(arguments);
  this._throttledProcessEmitStack();
}

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
  this.bufferedSocketEmit('getPublicKey', uuid, function(error, publicKey) {
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
          console.error('error resolving callback', err);
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
    this.socket.on('reconnect_error', this.emit.bind(this, 'reconnect_error'));
    this.socket.on('connect_error', this.emit.bind(this, 'connect_error'));
    this.socket.on('connect_timeout', this.emit.bind(this, 'connect_timeout'));
    this.socket.on('identify', this.identify.bind(this));
    this.socket.on('ready', this._ready.bind(this));
    this.socket.on('notReady', this._notReady.bind(this));
    this.socket.on('tb', this.emit.bind(this, 'tb'));
    this.socket.on('unboundSocket', this.emit.bind(this, 'unboundSocket'));
    this.socket.on('unregistered', this.emit.bind(this, 'unregistered'));
    this.socket.on('upgradeError', this.emit.bind(this, 'error'));
    this.socket.on('error', this.emit.bind(this, 'error'));

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

      setTimeout(function(){
        if(self._callbackHandlers[ack]){
          self._callbackHandlers[ack]({error: 'timeout ' + timeout});
          delete self._callbackHandlers[ack];
        }
      }, timeout);
    }
    this.bufferedSocketEmit(topic, data);
  }
  return this;
};

Connection.prototype._messageAck = function(response){
  this.bufferedSocketEmit('messageAck', response);
  return this;
};

Connection.prototype._ready = function(data){
  var self = this;
  clearTimeout(self.connectionTimer);
  self.connectionTimer = undefined;
  debug('clearing connectionTimer');
  debug('ready', data);
  self.options.uuid = data.uuid;
  if(data.token) {
    self.options.token = data.token;
  }

  if (!self.options.skip_resubscribe_on_reconnect) {
    _.each(self.subscriptions, function(subscription){
      self.bufferedSocketEmit('subscribe', subscription);
    });
  }

  self.emit('ready', data);
};

Connection.prototype._notReady = function(data){
  var self = this;
  clearTimeout(self.connectionTimer);
  self.connectionTimer = undefined;
  debug('clearing connectionTimer');
  data = data || {};
  debug('notReady', data);
  if(data.error != null && parseInt(data.error.code) === 429){
    self.reconnect();
  }
  debug('emitting notReady');
  self.emit('notReady', data);
};

Connection.prototype.connect = function(){
  var self = this;
  debug('connecting...');
  var socketOptions = _.defaults(
    _.clone(self.options.options),
    {'force new connection': true}
  );

  debug('parsing URL', self.options.server, self.options.port);
  var serverUrl = self.parseUrl(self.options.server, self.options.port) || DEFAULT_MESHBLU_URI;
  debug('serverUrl', serverUrl);
  self.socket = socketIoClient(serverUrl, socketOptions);
  debug('creating connectionTimer', self.connectionTimeout);
  self.connectionTimer = setTimeout(function(){self.emit('notReady', {status: 504, message: 'Connection Timeout'})}, self.connectionTimeout);
  self.setup();
};

Connection.prototype.reconnect = function(){
  var self = this;
  debug('reconnecting...');
  var randomNumber =  Math.random() * 5;
  clearTimeout(timeout);
  timeout = setTimeout(function(){
    self.connect();
  }, backoff.duration() * randomNumber);
};

Connection.prototype.identify = function(){
  this.bufferedSocketEmit('identity', {
    uuid: this.options.uuid,
    token: this.options.token,
    protocol: 'websocket',
    auto_set_online: this.options.auto_set_online
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
  this.bufferedSocketEmit('update', data, fn);
  return this;
};

Connection.prototype.register = function(data, fn) {
  this.bufferedSocketEmit('register', data, fn);
  return this;
};

Connection.prototype.unregister = function(data, fn) {
  this.bufferedSocketEmit('unregister', data, fn);
  return this;
};

Connection.prototype.claimdevice = function(data, fn) {
  this.bufferedSocketEmit('claimdevice', data, fn);
  return this;
};

Connection.prototype.whoami = function(data, fn) {
  this.bufferedSocketEmit('whoami', data, fn);
  return this;
};

Connection.prototype.device = function(data, fn) {
  this.bufferedSocketEmit('device', data, fn);
  return this;
};

Connection.prototype.devices = function(data, fn) {
  this.bufferedSocketEmit('devices', data, fn);
  return this;
};

Connection.prototype.mydevices = function(data, fn) {
  this.bufferedSocketEmit('mydevices', data, fn);
  return this;
};

Connection.prototype.status = function(data, fn) {
  this.bufferedSocketEmit('status', data, fn);
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
  this.bufferedSocketEmit('subscribe', uuidOrObject(data), fn);
  return this;
};

Connection.prototype.unsubscribe = function(data, fn) {
  this.bufferedSocketEmit('unsubscribe', uuidOrObject(data), fn);
  this.subscriptions = _.reject(this.subscriptions, uuidOrObject(data));
  return this;
};

Connection.prototype.authenticate = function(data, fn) {
  this.bufferedSocketEmit('authenticate', data, fn);
  return this;
};

Connection.prototype.events = function(data, fn) {
  this.bufferedSocketEmit('events', data, fn);
  return this;
};

Connection.prototype.data = function(data, fn) {
  this.bufferedSocketEmit('data', data, fn);
  return this;
};

Connection.prototype.getdata = function(data, fn) {
  this.bufferedSocketEmit('getdata', data, fn);
  return this;
};

Connection.prototype.localdevices = function(fn) {
  this.bufferedSocketEmit('localdevices', {}, fn);
  return this;
};

Connection.prototype.unclaimeddevices = function(data, fn) {
  this.bufferedSocketEmit('unclaimeddevices', data, fn);
  return this;
};

Connection.prototype.textBroadcast = function(data) {
  if(typeof data !== 'string'){
    data = String(data);
  }
  this.bufferedSocketEmit('tb', data);
  return this;
};

Connection.prototype.directText = function(data) {
  if(typeof data === 'object' && data.payload && typeof data.payload === 'string' && data.devices){
    this.bufferedSocketEmit('directText', data);
  }
  else{
    console.error('directText requires an object with a string payload property, and a devices property');
  }

  return this;
};

Connection.prototype.subscribeText = function(data, fn) {
  this.bufferedSocketEmit('subscribeText', uuidOrObject(data), fn);
  return this;
};

Connection.prototype.unsubscribeText = function(data, fn) {
  this.bufferedSocketEmit('unsubscribeText', uuidOrObject(data), fn);
  return this;
};

Connection.prototype.close = function(fn){
  this.socket.close(fn);
  return this;
};

Connection.prototype.resetToken = function(data, fn){
  this.bufferedSocketEmit('resetToken', uuidOrObject(data), fn);
};

Connection.prototype.generateAndStoreToken = function(data, fn){
  this.bufferedSocketEmit('generateAndStoreToken', data, fn);
};

Connection.prototype.revokeToken = function(data, fn){
  this.bufferedSocketEmit('revokeToken', data, fn);
};

Connection.prototype.revokeTokenByQuery = function(data, fn){
  this.bufferedSocketEmit('revokeTokenByQuery', data, fn);
};

module.exports = Connection;
