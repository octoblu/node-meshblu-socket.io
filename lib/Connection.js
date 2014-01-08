var io = require("socket.io-client");
var mqtt = require("mqtt");
var util = require('util');
var EventEmitter = require('events').EventEmitter;

function Connection(opt){
  EventEmitter.call(this);
  this.options = opt || {};
  // this.socket = io.connect(this.options.host, {
  //   port: this.options.port
  // });
  // this.socket = io.connect("localhost", {
  //   port: 3000
  // });
  this.socket = io.connect("http://skynet.im", {
    port: 80
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
      // this.mqttclient = mqtt.createClient(1883, 'localhost', mqttsettings);
      this.mqttclient = mqtt.createClient(1883, 'mqtt.skynet.im', this.mqttsettings);

      this.mqttclient.subscribe(this.options.uuid, {qos: this.options.qos});
      this.mqttclient.subscribe('broadcast', {qos: this.options.qos});
    } catch(err) {
      console.log(err);
    }  
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

    this.socket.on('disconnect', this.emit.bind(this, 'disconnect'));
    this.socket.on('identify', this.identify.bind(this));
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

// Connection.prototype.send = function(data) {
Connection.prototype.message = function(data) {
  
  // Send the API request to Skynet  
  if (typeof data !== 'object'){
    data = JSON.parse(data);
  }
  data.protocol = this.options.protocol;

  this.socket.emit('message', JSON.stringify(data));

  if (this.options.protocol == "mqtt"){
    // Publish to MQTT
    if(data.devices == "all" || data.devices == "*"){
      this.mqttclient.publish('broadcast', JSON.stringify(data.message), {qos: this.options.qos});
    } else {
      
      if( typeof data.devices === 'string' ) {
        devices = [ data.devices ];
      } else {
        devices = data.devices;
      };

      for (var i = 0; i < devices.length; i++) {
        this.mqttclient.publish(devices[i], JSON.stringify(data.message), {qos: this.options.qos});
      };

    }
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

Connection.prototype.events = function(data, fn) {
  this.socket.emit('events', data, fn);
  return this;
};


Connection.prototype.close = function(){
  return this;
};

module.exports = Connection;