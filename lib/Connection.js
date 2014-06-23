var mqtt = require("mqtt");
var util = require('util');
var EventEmitter = require('events').EventEmitter;
var io = require("socket.io-client");

function Connection(opt){

  EventEmitter.call(this);

  this.options = opt || {};
  this.options.forceNew = (opt.forceNew != null) ? opt.forceNew : false;

  this.socket = io.connect(this.options.server || "http://skynet.im", {
    port: this.options.port || 80,
    forceNew: this.options.forceNew,
    multiplex: !this.options.forceNew,
    'force new connection': this.options.forceNew
  });

  // mqttclient connection
  if (this.options.protocol == "mqtt") {
    this.mqttsettings = {
      keepalive: 1000,
      protocolId: 'MQIsdp',
      protocolVersion: 3,
      clientId: this.options.uuid
    }

    if (this.options.qos == undefined){
      this.options.qos = 0;
    }

    try {
      this.mqttclient = mqtt.createClient(this.options.mqttport || 1883, this.options.mqtthost || 'mqtt.skynet.im', this.mqttsettings);


      this.mqttclient.subscribe(this.options.uuid, {qos: this.options.qos});
      this.mqttclient.subscribe('broadcast', {qos: this.options.qos});
    } catch(err) {
      console.log(err);
    }
  } else {
    this.options.protocol = "websocket";

  }

  this.setup();
}

util.inherits(Connection, EventEmitter);

Connection.prototype.setup = function(){
  this.socket.once('connect', function(){
    this.emit('connect');

    if (this.options.protocol == "mqtt"){
      this.mqttclient.on('message', this.emit.bind(this, 'message'));
    } else {
      this.socket.on('message', this.emit.bind(this, 'message'));
    }

    this.socket.on('config', this.emit.bind(this, 'config'));
    this.socket.on('disconnect', this.emit.bind(this, 'disconnect'));
    this.socket.on('identify', this.identify.bind(this));
    this.socket.on('ready', this.emit.bind(this, 'ready'));
    this.socket.on('notReady', this.emit.bind(this, 'notReady'));
    this.socket.on('bindSocket', this.emit.bind(this, 'bindSocket'));
    this.socket.on('unboundSocket', this.emit.bind(this, 'unboundSocket'));

  }.bind(this));

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

  // Send the API request to Skynet
  if (typeof data !== 'object'){
    try{
      data = JSON.parse(data);
    } catch(e){
      data = {payload: data};
    }
  }

  if(data.payload == undefined){
    data.payload = data.message;
    try{
      delete data["message"];
    } catch (e){
      console.log(e);
    }
  }

  data.protocol = this.options.protocol;
  data.fromUuid = this.options.uuid;
  data.qos = this.options.qos;

  if(this.options.protocol == "mqtt"){
    this.mqttclient.publish('skynet', JSON.stringify(data), {qos: this.options.qos});
  }else{
    this.socket.emit('message', data, fn);
  }

  return this;
};

// send plain text
Connection.prototype.send = function(text) {

  if(text){
    text = text.toString();
    this.socket.send(text);
  }

  return this;
};

Connection.prototype.config = function(data, fn) {
  this.socket.emit('gatewayConfig', data, fn);
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

Connection.prototype.mydevices = function(data, fn) {
  this.socket.emit('mydevices', data, fn);
  return this;
};

Connection.prototype.bindSocket = function(data, fn) {
  this.socket.emit('bindSocket', data, fn);
  return this;
};

Connection.prototype.gatewayConfig = function(data, fn) {
  this.socket.emit('gatewayConfig', data, fn);
  return this;
};

Connection.prototype.status = function(data) {
  this.socket.emit('status', data);
  return this;
};

Connection.prototype.subscribe = function(data, fn) {
  this.socket.emit('subscribe', data, fn);
  if (this.options.protocol == "mqtt") {
    this.mqttclient.subscribe(data.uuid, {qos: this.options.qos});
  }
  return this;
};

Connection.prototype.unsubscribe = function(data, fn) {
  this.socket.emit('unsubscribe', data, fn);
  if (this.options.protocol == "mqtt") {
    this.mqttclient.subscribe(data.uuid);
  }
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

Connection.prototype.close = function(){
  return this;
};

module.exports = Connection;
