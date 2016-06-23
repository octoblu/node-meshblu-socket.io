dns            = require 'dns'
{EventEmitter} = require 'events'
_              = require 'lodash'
socketIoClient = require 'socket.io-client'
url            = require 'url'

DEFAULT_BUFFER_RATE = 100

class BufferedSocket extends EventEmitter
  constructor: (options, dependencies={}) ->
    @_socketIoClient = dependencies.socketIoClient ? socketIoClient
    @_dns = dependencies.dns ? dns
    @_options = options
    @_socketIoOptions = _.defaults options.socketIoOptions, {forceNew: true}

    @_emitStack = []
    @_throttledProcessEmitStack = _.throttle @_processEmitStack, (@_options.bufferRate ? DEFAULT_BUFFER_RATE)

  connect: (callback) =>
    @_resolveUri (error, uri) =>
      return callback error if error?
      @_socket = @_socketIoClient(uri, @_socketIoOptions)
      @_socket.once 'connect', => callback()
      @_socket.on 'identify',  => @emit 'identify', arguments
      @_socket.on 'ready',     => @emit 'ready', arguments

  send: =>
    @_emitStack.push arguments
    @_throttledProcessEmitStack()

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

  _processEmitStack: =>
    console.log '_processEmitStack'
    return if _.isEmpty @_emitStack

    args = @_emitStack.shift()
    console.log 'emit', args...
    @_socket.emit args...

    _.defer @_throttledProcessEmitStack

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


module.exports = BufferedSocket
