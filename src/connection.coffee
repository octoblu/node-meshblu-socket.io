dns            = require 'dns'
_              = require 'lodash'
socketIoClient = require 'socket.io-client'
url            = require 'url'

BufferedSocket = require './buffered-socket'

class Connection
  constructor: (options, dependencies={}) ->
    @_dns             = dependencies.dns
    @_dns            ?= dns
    @_socketIoClient  = dependencies.socketIoClient
    @_socketIoClient ?= socketIoClient

    @_options = options
    @_subscriptions = []

  connect: (callback) =>
    @_resolveUri (error, uri) =>
      console.log '_resolveUri', error, uri
      @_socket = new BufferedSocket {uri, socketIoClient: @_socketIoClient}
      @_socket.on 'identify', @_onIdentify
      @_socket.on 'ready', @_onReady
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
