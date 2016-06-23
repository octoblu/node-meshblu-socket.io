stableStringify = require 'json-stable-stringify'
{EventEmitter}  = require 'events'
_               = require 'lodash'
NodeRSA         = require 'node-rsa'
url             = require 'url'

BufferedSocket = require './buffered-socket'

class Connection extends EventEmitter
  constructor: (options, dependencies={}) ->
    @_BufferedSocket = dependencies.BufferedSocket ? BufferedSocket
    @_console        = dependencies.console ? console

    @_options = options
    @_subscriptions = []
    @_privateKey = new NodeRSA options.privateKey if options.privateKey

    {socket, protocol, hostname, port, service, domain, secure, resolveSrv, options} = options
    @_socket = @_buildSocket {socket, protocol, hostname, port, service, domain, secure, resolveSrv, options}
    @_socket.on 'config', @_onConfig
    @_socket.on 'identify', @_onIdentify
    @_socket.on 'message', @_onMessage
    @_socket.on 'ready', @_onReady

  connect: (callback) =>
    @_socket.connect(callback)

  encryptMessage: (uuid, toEncrypt, message, callback) =>
    if _.isFunction message
      callback = message
      message  = undefined

    @_socket.send 'getPublicKey', uuid, (error, publicKey) =>
      return @_console.error "can't find public key for device" if error?
      encryptedPayload = @_encrypt {publicKey, data: toEncrypt}
      @_socket.send 'message', _.defaults({encryptedPayload}, message), callback

  generateKeyPair: (bits) =>
    key = new NodeRSA
    key.generateKeyPair(bits)
    return {
      privateKey: key.exportKey 'private'
      publicKey:  key.exportKey 'public'
    }

  identify: =>
    {uuid, token, auto_set_online} = @_options
    @_socket.send 'identity', {uuid, token, auto_set_online}

  message: (message, callback) =>
    @_socket.send 'message', message, callback

  resetToken: (data, callback) =>
    data = @_uuidOrObject data
    @_socket.send 'resetToken', data, callback

  sign: (data) =>
    @_privateKey.sign stableStringify(data), 'base64'

  subscribe: (data) =>
    data = @_uuidOrObject data

    @subscriptions = _.unionBy @subscriptions, [data], _.isEqual
    @_socket.send 'subscribe', data

  unsubscribe: (data) =>
    data = @_uuidOrObject data
    @subscriptions = _.reject @subscriptions, data

    @_socket.send 'unsubscribe', data

  verify: (data, signature) =>
    @_privateKey.verify stableStringify(data), signature, 'utf8', 'base64'

  _assertNoSrv: ({service, domain, secure}) =>
    throw new Error('resolveSrv is set to false, but received domain')  if domain?
    throw new Error('resolveSrv is set to false, but received service') if service?
    throw new Error('resolveSrv is set to false, but received secure')  if secure?

  _assertNoUrl: ({protocol, hostname, port}) =>
    throw new Error('resolveSrv is set to true, but received protocol') if protocol?
    throw new Error('resolveSrv is set to true, but received hostname') if hostname?
    throw new Error('resolveSrv is set to true, but received port')     if port?

  _buildSocket: ({socket, protocol, hostname, port, service, domain, secure, resolveSrv, options}) =>
    return socket if socket?

    return @_buildSrvSocket({protocol, hostname, port, service, domain, secure, options}) if resolveSrv
    return @_buildUrlSocket({protocol, hostname, port, service, domain, secure, options})

  _buildSrvSocket: ({protocol, hostname, port, service, domain, secure, options}) =>
    @_assertNoUrl({protocol, hostname, port})
    service ?= 'meshblu'
    domain  ?= 'octoblu.com'
    secure  ?= true
    return new @_BufferedSocket {resolveSrv: true, service, domain, secure, options}

  _buildUrlSocket: ({protocol, hostname, port, service, domain, secure, options}) =>
    @_assertNoSrv({service, domain, secure})
    protocol ?= 'wss'
    hostname ?= 'meshblu-socket-io.octoblu.com'
    port     ?= 443
    try port = parseInt port
    return new @_BufferedSocket {resolveSrv: false, protocol, hostname, port, options}

  _decrypt: ({data}) =>
    return JSON.parse @_privateKey.decrypt data

  _encrypt: ({publicKey, data}) =>
    return new NodeRSA(publicKey).encrypt stableStringify(data), 'base64'

  _onConfig: (config) => @emit 'config', config

  _onIdentify: => @identify()

  _onMessage: (message) =>
    message.encryptedPayload = @_decrypt({data: message.encryptedPayload}) if message.encryptedPayload?
    @emit 'message', message

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
