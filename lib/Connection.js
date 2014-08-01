'use strict';
var util = require('util');
var EventEmitter = require('events').EventEmitter;
var socketIoClient = require("socket.io-client");

var DEFAULT_TIMEOUT = 10000;

function Connection(opt){

  EventEmitter.call(this);

  this._callbackHandlers = {};
  this._ackId = 0;

  this.options = opt || {};
  this.options.options = this.options.options || {};

  this.options.options.transports = this.options.options.transports || ['websocket'];
  this.options.forceNew = (opt.forceNew != null) ? opt.forceNew : false;

  this.options.server = this.options.server || 'ws://skynet.im';
  this.options.port = this.options.port || 80;



  // if(this.options.server && this.options.port){
     if(this.options.server.indexOf("http") === -1 && this.options.server.indexOf("ws") === -1 && this.options.server.indexOf("wss") === -1 ){
       this.options.server = "ws://" + this.options.server;
     }
  //   network = this.options.server + ":" + this.options.port;
  // }
  var network = this.options.server + ':' + this.options.port;
  console.log('trying', network);
  this.socket = socketIoClient(network, this.options.options); // || "ws://skynet.im");

  // this.socket = io.connect(this.options.server || "http://skynet.im", {
  //   port: this.options.port || 80,
  //   forceNew: this.options.forceNew,
  //   multiplex: !this.options.forceNew,
  //   'force new connection': this.options.forceNew
  // });

  this.options.protocol = "websocket";
  this.setup();
}

util.inherits(Connection, EventEmitter);

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

      //this.emit.bind(this, 'message'));
    this.socket.on('config', function(data){
      self._handleAckRequest('config', data);
    });

    this.socket.on('disconnect', this.emit.bind(this, 'disconnect'));
    this.socket.on('identify', this.identify.bind(this));
    this.socket.on('ready', this.emit.bind(this, 'ready'));
    this.socket.on('notReady', this.emit.bind(this, 'notReady'));
    this.socket.on('tb', this.emit.bind(this, 'tb'));
    this.socket.on('unboundSocket', this.emit.bind(this, 'unboundSocket'));

  }.bind(this));

  return this;
};

//Provide callback when message with ack requests comes in from another client
Connection.prototype._handleAckRequest = function(topic, data){
  var self = this;
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
    //console.log('emitting ack', topic, data);
    this.socket.emit(topic, data);
  }
  return this;
};

Connection.prototype._messageAck = function(response){
  this.socket.emit('messageAck', response);
  return this;
};



Connection.prototype.identify = function(){
  this.socket.emit('identity', {
    uuid: this.options.uuid,
    token: this.options.token,
    protocol: this.options.protocol
  });
  return this;
};


Connection.prototype.message = function(data, fn) {
  return this._emitWithAck('message', data, fn);
};

Connection.prototype.config = function(data, fn) {
  return this._emitWithAck('gatewayConfig', data, fn);
};

Connection.prototype.gatewayConfig = function(data, fn) {
  return this._emitWithAck('gatewayConfig', data, fn);
};

// send plain text
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

Connection.prototype.subscribe = function(data, fn) {
  if(typeof data === 'string'){
    data = {uuid: data};
  }
  this.socket.emit('subscribe', data, fn);
  return this;
};

Connection.prototype.unsubscribe = function(data, fn) {
  if(typeof data === 'string'){
    data = {uuid: data};
  }
  this.socket.emit('unsubscribe', data, fn);
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
  if(typeof data === 'string'){
    data = {uuid: data};
  }
  this.socket.emit('subscribeText', data, fn);
  return this;
};

Connection.prototype.unsubscribeText = function(data, fn) {
  if(typeof data === 'string'){
    data = {uuid: data};
  }
  this.socket.emit('unsubscribeText', data, fn);
  return this;
};


Connection.prototype.close = function(fn){
  this.socket.close(fn);
  return this;
};



module.exports = Connection;
