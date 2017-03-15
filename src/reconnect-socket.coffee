Backoff     = require 'backo'
_           = require 'lodash'
ProxySocket = require './proxy-socket'
SrvSocket   = require './srv-socket'

DEFAULT_BACKOFF_MIN = 0
DEFAULT_BACKOFF_MAX = 30 * 1000
DEFAULT_CONNECTION_TIMEOUT = 30 * 1000
DEFAULT_JITTER = 0.5

class ReconnectSocket extends ProxySocket
  constructor: (options={}, dependencies={}) ->
    @_connectionTimeout = options.connectionTimeout ? DEFAULT_CONNECTION_TIMEOUT

    @_backoff = new Backoff {
      min: options.backoffMin ? DEFAULT_BACKOFF_MIN
      max: options.backoffMax ? DEFAULT_BACKOFF_MAX
      jitter: options.jitter ? DEFAULT_JITTER
    }

    @SrvSocket = dependencies.SrvSocket ? SrvSocket
    @closing = false

    @_socket = new @SrvSocket options.srvOptions
    @_socket.on 'ready', @_onReady
    @_socket.on 'connect', @_onConnect
    @_socket.on 'disconnect', @_onDisconnect

    super # Must be called after @_socket is assigned

  close: (callback) =>
    return callback() if @closing
    @closing = true
    @_socket.close callback

  connect: (callback) =>
    throw new Error 'connect should not take a callback' if callback?
    @_connectTimeout = setTimeout @_onConnectionTimeout, @_connectionTimeout
    @_socket.connect()

  send: =>
    @_socket.send arguments...

  _onReady: =>
    @_backoff.reset()

  _onConnect: =>
    clearTimeout @_connectTimeout

  _onDisconnect: =>
    return if @closing
    clearTimeout @_reconnectTimeout
    backoff = @_backoff.duration()
    @_reconnectTimeout = setTimeout @connect, backoff

  _onConnectionTimeout: (callback) =>
    return if @closing
    @emit 'notReady', {status: 504, message: 'Connection Timeout'}
    @_onDisconnect()

module.exports = ReconnectSocket
