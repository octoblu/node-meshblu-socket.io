Backoff        = require 'backo'
dns            = require 'dns'
_              = require 'lodash'
socketIoClient = require 'socket.io-client'
SrvFailover    = require 'srv-failover'
url            = require 'url'
ProxySocket    = require './proxy-socket'

class SrvSocket extends ProxySocket
  constructor: ({protocol, hostname, port, service, domain, secure, resolveSrv, socketIoOptions}, dependencies={}) ->
    @_socketIoClient = dependencies.socketIoClient ? socketIoClient
    @_dns = dependencies.dns ? dns
    @_options = {protocol, hostname, port, service, domain, secure, resolveSrv}
    @_socketIoOptions = _.defaults {}, socketIoOptions, {forceNew: true, reconnect: false}

    @backoff = new Backoff

    return unless resolveSrv
    srvProtocol = 'socket-io-wss'
    urlProtocol = 'wss'

    if secure == false
      srvProtocol = 'socket-io-ws'
      urlProtocol = 'ws'

    @_srvFailover = new SrvFailover {domain, service, protocol: srvProtocol, urlProtocol}, dns: @_dns

  close: (callback) =>
    return callback() unless @_socket?
    @_socket.once 'disconnect', => callback()
    @_socket.close()

  connect: (callback) =>
    callback = _.once callback

    @_resolveUri (error, uri) =>
      return callback error if error?
      @_socket = @_socketIoClient(uri, @_socketIoOptions)
      @_socket.once 'connect', => callback()
      @_socket.once 'connect_error', (error) =>
        return callback error unless @_srvFailover?
        @_srvFailover.markBadUrl uri, ttl: 60000
        _.delay @connect, @backoff.duration(), callback

      @_proxyDefaultIncomingEvents() # From super

  send: =>
    @_socket.emit arguments...

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
