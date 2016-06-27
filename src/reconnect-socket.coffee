Backoff     = require 'backo'
_           = require 'lodash'
ProxySocket = require './proxy-socket'
SrvSocket   = require './srv-socket'

DEFAULT_BACKOFF_MIN = 1000
DEFAULT_BACKOFF_MAX = 60 * 60 * 1000
DEFAULT_CONNECTION_TIMEOUT = 30000

class ReconnectSocket extends ProxySocket
  constructor: (options={}, dependencies={}) ->
    @_connectionTimeout = options.connectionTimeout ? DEFAULT_CONNECTION_TIMEOUT

    @_backoff = new Backoff {
      min: options.backoffMin ? DEFAULT_BACKOFF_MIN
      max: options.backoffMax ? DEFAULT_BACKOFF_MAX
    }

    @SrvSocket = dependencies.SrvSocket ? SrvSocket

    @_socket = new @SrvSocket options.srvOptions
    @_socket.on 'notReady', @_onNotReady

    super # Must be called after @_socket is assigned

  close: (callback) =>
    @_socket.close callback

  connect: (callback) =>
    callback = _.once callback

    onConnectionTimeout = setTimeout (=> @_onConnectionTimeout callback), @_connectionTimeout

    @_socket.connect (error) =>
      clearTimeout onConnectionTimeout
      callback error

    setTimeout

  send: =>
    @_socket.send arguments...

  _onConnectionTimeout: (callback) =>
    @emit 'notReady', {status: 504, message: 'Connection Timeout'}
    callback new Error 'Connection Timeout'

  _onNotReady: (data) =>
    return unless 429 == _.get(data, 'error.code')
    @_reconnect()

  _reconnect: =>
    randomFloat = _.random 1, 5, true
    duration    = @_backoff.duration() * randomFloat

    clearTimeout @_reconnectTimeout
    @_reconnectTimeout = setTimeout @_socket.connect, duration


module.exports = ReconnectSocket
