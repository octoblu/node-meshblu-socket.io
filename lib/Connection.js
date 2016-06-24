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
var DEFAULT_MESHBLU_URI = 'wss://meshblu-socket-io.octoblu.com';

function Connection(opt, dependencies){

  var connectionTimeout = opt.connectionTimeout
  if (_.isNull(connectionTimeout) || _.isUndefined(connectionTimeout)) {
    connectionTimeout = DEFAULT_CONNECTION_TIMEOUT;
  }

  this.connectionTimeout = connectionTimeout;
}

Connection.prototype.setup = function(){
  this.socket.on('notReady', this._notReady.bind(this));
  this.socket.on('ready', this._ready.bind(this));
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
  this.socket.once('disconnect', function(){fn()});
  this.socket.close();
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
