{EventEmitter} = require 'events'
_              = require 'lodash'

PROXIED_EVENTS = [ 'config', 'connect', 'disconnect', 'error', 'identify', 'message', 'notReady', 'ready' ]

class ProxySocket extends EventEmitter
  constructor: ->
    return unless @_socket?
    @_proxyDefaultIncomingEvents()

  _proxyIncomingEvent: (event) =>
    @_socket.on event, => @emit event, arguments...

  _proxyIncomingEvents: (events) =>
    _.each events, @_proxyIncomingEvent

  _proxyDefaultIncomingEvents: =>
    @_proxyIncomingEvents PROXIED_EVENTS


module.exports = ProxySocket
