var EventEmitter, PROXIED_EVENTS, ProxySocket, _,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty,
  slice = [].slice;

EventEmitter = require('events').EventEmitter;

_ = require('lodash');

PROXIED_EVENTS = ['config', 'connect', 'disconnect', 'error', 'identify', 'message', 'notReady', 'ratelimited', 'ready'];

ProxySocket = (function(superClass) {
  extend(ProxySocket, superClass);

  function ProxySocket() {
    this._proxyDefaultIncomingEvents = bind(this._proxyDefaultIncomingEvents, this);
    this._proxyIncomingEvents = bind(this._proxyIncomingEvents, this);
    this._proxyIncomingEvent = bind(this._proxyIncomingEvent, this);
    if (this._socket == null) {
      return;
    }
    this._proxyDefaultIncomingEvents();
  }

  ProxySocket.prototype._proxyIncomingEvent = function(event) {
    if (this._socket == null) {
      throw new Error("Missing required instance variable: @_socket");
    }
    return this._socket.on(event, (function(_this) {
      return function() {
        return _this.emit.apply(_this, [event].concat(slice.call(arguments)));
      };
    })(this));
  };

  ProxySocket.prototype._proxyIncomingEvents = function(events) {
    if (this._socket == null) {
      throw new Error("Missing required instance variable: @_socket");
    }
    return _.each(events, (function(_this) {
      return function(event) {
        return _this._proxyIncomingEvent(event);
      };
    })(this));
  };

  ProxySocket.prototype._proxyDefaultIncomingEvents = function() {
    if (this._socket == null) {
      throw new Error("Missing required instance variable: @_socket");
    }
    return this._proxyIncomingEvents(PROXIED_EVENTS);
  };

  return ProxySocket;

})(EventEmitter);

module.exports = ProxySocket;

// ---
// generated by coffee-script 1.9.2
