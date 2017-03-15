{EventEmitter} = require 'events'
_              = require 'lodash'

PROXIED_EVENTS = [
  'config'
  'connect'
  'disconnect'
  'error'
  'identify'
  'message'
  'notReady'
  'ratelimited'
  'ready'
]

class ProxySocket extends EventEmitter
  constructor:  ({socket}) ->
    @_socket = socket if socket?
    @_proxyDefaultIncomingEvents()

  _proxyIncomingEvent: (event) =>
    throw new Error("Missing required instance variable: @_socket") unless @_socket?
    @_socket.on event, => @emit event, arguments...

  _proxyIncomingEvents: (events) =>
    throw new Error("Missing required instance variable: @_socket") unless @_socket?
    _.each events, (event) =>
      @_proxyIncomingEvent event
    # _.each events, @_proxyIncomingEvent # Doesn't work, don't know why. Prolly an inheritance problem?

  _proxyDefaultIncomingEvents: =>
    throw new Error("Missing required instance variable: @_socket") unless @_socket?
    @_proxyIncomingEvents PROXIED_EVENTS


module.exports = ProxySocket
