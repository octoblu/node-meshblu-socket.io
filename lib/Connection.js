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
    this.socket.on('update', this.emit.bind(this, 'update'));
    this.socket.on('message', this.emit.bind(this, 'message'));
    this.socket.on('disconnect', this.emit.bind(this, 'disconnect'));

    this.socket.on('identify', this.identify.bind(this));
    this.socket.on('authentication', this.emit.bind(this, 'authentication'))

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

Connection.prototype.update = function(data) {
  this.socket.emit('update', data);
  return this;
};


Connection.prototype.close = function(){
  return this;
};

module.exports = Connection;