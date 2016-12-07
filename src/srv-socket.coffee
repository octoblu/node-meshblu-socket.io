dns            = require 'dns'
_              = require 'lodash'
socketIoClient = require 'socket.io-client'
url            = require 'url'
ProxySocket    = require './proxy-socket'

class SrvSocket extends ProxySocket
  constructor: ({protocol, hostname, port, service, domain, secure, resolveSrv, socketIoOptions}, dependencies={}) ->
    @_socketIoClient = dependencies.socketIoClient ? socketIoClient
    @_dns = dependencies.dns ? dns
    @_options = {protocol, hostname, port, service, domain, secure, resolveSrv}
    @_socketIoOptions = _.defaults {}, socketIoOptions, {forceNew: true}

  close: (callback) =>
    return callback() unless @_socket?
    @_socket.once 'disconnect', => callback()
    @_socket.close()

  connect: (callback) =>
    @_resolveUri (error, uri) =>
      return callback error if error?
      @_socket = @_socketIoClient(uri, @_socketIoOptions)
      @_socket.once 'connect', => callback()

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
    {protocol, hostname, port, resolveSrv} = @_options
    return callback null, url.format({protocol, hostname, port, slashes: true}) unless resolveSrv

    @_dns.resolveSrv @_getSrvAddress(), (error, addresses) =>
      return callback error if error?
      return callback new Error('SRV record found, but contained no valid addresses') if _.isEmpty addresses
      return callback null, @_resolveUrlFromAddresses(addresses)

  _resolveUrlFromAddresses: (addresses) =>
    address = _.minBy addresses, 'priority'
    return url.format {
      protocol: @_getSrvConnectionProtocol()
      hostname: address.name
      port: address.port
      slashes: true
    }

module.exports = SrvSocket
