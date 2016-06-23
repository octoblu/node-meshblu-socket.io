dns            = require 'dns'
_              = require 'lodash'
url            = require 'url'

BufferedSocket = require './buffered-socket'

class Connection
  constructor: (options, dependencies={}) ->
    @_BufferedSocket = dependencies.BufferedSocket ? BufferedSocket

    @_options = options
    @_subscriptions = []

    {socket, protocol, hostname, port, service, domain, secure, resolveSrv, socketIoClient} = options
    @_socket = @_buildSocket {socket, protocol, hostname, port, service, domain, secure, resolveSrv, socketIoClient}
    @_socket.on 'identify', @_onIdentify
    @_socket.on 'ready', @_onReady

  connect: (callback) =>
    @_socket.connect(callback)

  identify: =>
    @_socket.send 'identity', {
      uuid:  @_options.uuid
      token: @_options.token
      auto_set_online: @_options.auto_set_online
    }

  resetToken: =>

  subscribe: (data) =>
    data = @_uuidOrObject data

    @subscriptions = _.unionBy @subscriptions, [data], _.isEqual
    @_socket.send 'subscribe', data

  unsubscribe: (data) =>
    data = @_uuidOrObject data
    @subscriptions = _.reject @subscriptions, data

    @_socket.send 'unsubscribe', data

  _assertNoSrv: ({service, domain, secure}) =>
    throw new Error('resolveSrv is set to false, but received domain')  if domain?
    throw new Error('resolveSrv is set to false, but received service') if service?
    throw new Error('resolveSrv is set to false, but received secure')  if secure?

  _assertNoUrl: ({protocol, hostname, port}) =>
    throw new Error('resolveSrv is set to true, but received protocol') if protocol?
    throw new Error('resolveSrv is set to true, but received hostname') if hostname?
    throw new Error('resolveSrv is set to true, but received port')     if port?

  _buildSocket: ({socket, protocol, hostname, port, service, domain, secure, resolveSrv, socketIoClient}) =>
    return socket if socket?

    return @_buildSrvSocket({protocol, hostname, port, service, domain, secure, socketIoClient}) if resolveSrv
    return @_buildUrlSocket({protocol, hostname, port, service, domain, secure, socketIoClient})

  _buildSrvSocket: ({protocol, hostname, port, service, domain, secure, socketIoClient}) =>
    @_assertNoUrl({protocol, hostname, port})
    service ?= 'meshblu'
    domain ?= 'octoblu.com'
    secure ?= true
    return new @_BufferedSocket {resolveSrv: true, service, domain, secure}

  _buildUrlSocket: ({protocol, hostname, port, service, domain, secure, socketIoClient}) =>
    @_assertNoSrv({service, domain, secure})
    protocol ?= 'https'
    hostname ?= 'meshblu.octoblu.com'
    port     ?= 443
    try port = parseInt port
    return new @_BufferedSocket {resolveSrv: false, protocol, hostname, port}

  _onIdentify: => @identify()

  _onReady: =>
    _.each @subscriptions, @subscribe

  _resolveUri: (callback) =>
    return @_resolveSrv callback if @_options.resolveSrv

    {protocol, hostname, port} = @_options
    callback null, url.format {protocol, hostname, port, slashes: true}

  _resolveSrv: (callback) =>
    {service, domain} = @_options
    @_dns.resolveSrv "_#{service}._socket-io-wss.#{domain}", (error, addresses) =>
      return callback error if error?
      address = _.first addresses
      return callback null, url.format {protocol: 'wss', hostname: address.name, port: address.port, slashes: true}

  _uuidOrObject: (data) =>
    return {uuid: data} if _.isString data
    return data


module.exports = Connection
