var io = require("socket.io-client");

var util = require('util');
var EventEmitter = require('events').EventEmitter;

function Connection(opt){
  EventEmitter.call(this);
  this.options = opt || {};
  this.socket = io.connect(this.options.host, {
    port: this.options.port
  });

  this.setup();
}

util.inherits(Connection, EventEmitter);

Connection.prototype.setup = function(){
  this.socket.once('connect', function(){
    this.emit('connect');
    this.socket.on('message', this.emit.bind(this, 'message'));
    this.socket.on('disconnect', this.emit.bind(this, 'disconnect'));
    // this.socket.on('update', this.emit.bind(this, 'update'));
    // this.socket.on('register', this.emit.bind(this, 'register'));
    // this.socket.on('unregister', this.emit.bind(this, 'unregister'));
    // this.socket.on('whoami', this.emit.bind(this, 'whoami'));
    // this.socket.on('devices', this.emit.bind(this, 'devices'));
    // this.socket.on('status', this.emit.bind(this, 'status'));

    this.socket.on('identify', this.identify.bind(this));
    // this.socket.on('authentication', this.emit.bind(this, 'authentication'))
    this.socket.on('ready', this.emit.bind(this, 'ready'));
    this.socket.on('notReady', this.emit.bind(this, 'notReady'));

  }.bind(this));
  return this;
};

Connection.prototype.identify = function(){
  this.socket.emit('identity', {
    uuid: this.options.uuid,
    token: this.options.token
  });
  return this;
};

Connection.prototype.send = function(data) {
  this.socket.emit('message', data);
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

Connection.prototype.whoami = function(data, fn) {
  this.socket.emit('whoami', data, fn);
  return this;
};

Connection.prototype.devices = function(data, fn) {
  this.socket.emit('devices', data, fn);
  return this;
};

Connection.prototype.status = function(data) {
  this.socket.emit('status', data);
  return this;
};

Connection.prototype.subscribe = function(data, fn) {
  this.socket.emit('subscribe', data, fn);
  return this;
};

Connection.prototype.unsubscribe = function(data, fn) {
  this.socket.emit('unsubscribe', data, fn);
  return this;
};

Connection.prototype.events = function(data, fn) {
  this.socket.emit('events', data, fn);
  return this;
};


Connection.prototype.close = function(){
  return this;
};

module.exports = Connection;