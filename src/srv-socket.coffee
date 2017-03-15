Backoff        = require 'backo'
_              = require 'lodash'
SrvFailover    = require 'srv-failover'
url            = require 'url'
ProxySocket    = require './proxy-socket'

class SrvSocket extends ProxySocket
  constructor: ({protocol, hostname, port, service, domain, secure, resolveSrv, socketIoOptions}, @dependencies={}) ->
    @_options = {protocol, hostname, port, service, domain, secure, resolveSrv}
    @_socketIoOptions = _.defaults {}, socketIoOptions, {forceNew: true, reconnection: false}
    @backoff = new Backoff

    return unless resolveSrv
    srvProtocol = 'socket-io-wss'
    urlProtocol = 'wss'

    if secure == false
      srvProtocol = 'socket-io-ws'
      urlProtocol = 'ws'

    @_srvFailover = new SrvFailover {domain, service, protocol: srvProtocol, urlProtocol}, dns: @dependencies.dns

  close: (callback) =>
    return callback() unless @_socket?
    @_socket.once 'disconnect', => callback()
    @_socket.close()

  connect: (callback) =>
    throw new Error 'connect should not take a callback' if callback?

    delete require.cache[require.resolve('socket.io-client')]
    socketIoClient = require 'socket.io-client'
    _socketIoClient = @dependencies.socketIoClient ? socketIoClient

    @_resolveUri (error, uri) =>
      return @emit 'resolve-uri:error', error if error?
      @_socket = _socketIoClient(uri, @_socketIoOptions)
      @_socket.once 'connect', => @backoff.reset()
      @_socket.once 'connect_error', (error) =>
        @_srvFailover.markBadUrl uri, ttl: 60000 if @_srvFailover?
        backoff = @backoff.duration()
        _.delay @connect, backoff

      @_proxyDefaultIncomingEvents() # From super

  send: =>
    @_socket.emit arguments... if @_socket?

  _getSrvAddress: =>
    {service, domain} = @_options
    protocol = @_getSrvProtocol()
    return "_#{service}._#{protocol}.#{domain}"

  _getSrvConnectionProtocol: =>
    return 'wss' if @_options.secure
    return 'ws'

  _getSrvProtocol: =>
    return 'socket-io-wss' if @_options.secure
    return 'socket-io-ws'

  _resolveUri: (callback) =>
    {protocol, hostname, port} = @_options
    return callback null, url.format({protocol, hostname, port, slashes: true}) unless @_srvFailover?

    return @_srvFailover.resolveUrl (error, baseUrl) =>
      if error && error.noValidAddresses
        @_srvFailover.clearBadUrls()
        return @_resolveUri callback
      return callback error if error?
      return callback null, baseUrl

  _resolveUrlFromAddresses: (addresses) =>
    address = _.minBy addresses, 'priority'
    return url.format {
      protocol: @_getSrvConnectionProtocol()
      hostname: address.name
      port: address.port
      slashes: true
    }

module.exports = SrvSocket
