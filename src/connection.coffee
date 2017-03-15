stableStringify = require 'json-stable-stringify'
_               = require 'lodash'
NodeRSA         = require 'node-rsa'
url             = require 'url'

BufferedSocket = require './buffered-socket'
ProxySocket = require './proxy-socket'
{EventEmitter} = require 'events'

class Connection extends ProxySocket
  constructor: (options={}, dependencies={}) ->
    @_BufferedSocket = dependencies.BufferedSocket ? BufferedSocket
    @_console        = dependencies.console ? console

    @_options = options
    @_subscriptions = []
    @_privateKey = new NodeRSA options.privateKey if options.privateKey

    {socket, protocol, hostname, port, service, domain, secure, resolveSrv, bufferRate} = options
    srvOptions = {protocol, hostname, port, service, domain, secure, resolveSrv, socketIoOptions: options.options}
    @_socket = @_buildSocket {socket, srvOptions, bufferRate}
    super

    # these must happen after the call to super
    @_socket.removeAllListeners 'message' # override ProxySocket
    @_socket.on 'identify', @_onIdentify
    @_socket.on 'ready', @_onReady
    @_socket.on 'message', @_onMessage

  close: (callback=->) =>
    @_socket.close callback

  connect: (callback) =>
    throw new Error 'connect should not take a callback' if callback?
    @_socket.connect()

  device: (query, callback) =>
    @_socket.send 'device', query, callback

  devices: (query, callback) =>
    @_socket.send 'devices', query, callback

  encryptMessage: (uuid, toEncrypt, message, callback) =>
    if _.isFunction message
      callback = message
      message  = undefined

    @_socket.send 'getPublicKey', uuid, (error, publicKey) =>
      return @_console.error "can't find public key for device" if error?
      encryptedPayload = @_encrypt {publicKey, data: toEncrypt}
      @_socket.send 'message', _.defaults({encryptedPayload}, message), callback

  generateAndStoreToken: (query, callback) =>
    @_socket.send 'generateAndStoreToken', query, callback

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

  register: (query, callback) =>
    @_socket.send 'register', query, callback

  resetToken: (data, callback) =>
    data = @_uuidOrObject data
    @_socket.send 'resetToken', data, callback

  revokeToken: (auth, callback) =>
    @_socket.send 'revokeToken', auth, callback

  revokeTokenByQuery: (data, callback) =>
    @_socket.send 'revokeTokenByQuery', data, callback

  sign: (data) =>
    @_privateKey.sign stableStringify(data), 'base64'

  subscribe: (data) =>
    data = @_uuidOrObject data

    @subscriptions = _.unionBy @subscriptions, [data], _.isEqual
    @_socket.send 'subscribe', data

  unregister: (query, callback) =>
    @_socket.send 'unregister', query, callback

  unsubscribe: (data) =>
    data = @_uuidOrObject data
    @subscriptions = _.reject @subscriptions, data

    @_socket.send 'unsubscribe', data

  update: (query, callback) =>
    @_socket.send 'update', query, callback

  verify: (data, signature) =>
    @_privateKey.verify stableStringify(data), signature, 'utf8', 'base64'

  whoami: (callback) =>
    @_socket.send 'whoami', {}, callback

  _assertNoSrv: ({service, domain, secure}) =>
    throw new Error('resolveSrv is set to false, but received domain')  if domain?
    throw new Error('resolveSrv is set to false, but received service') if service?
    throw new Error('resolveSrv is set to false, but received secure')  if secure?

  _assertNoUrl: ({protocol, hostname, port}) =>
    throw new Error('resolveSrv is set to true, but received protocol') if protocol?
    throw new Error('resolveSrv is set to true, but received hostname') if hostname?
    throw new Error('resolveSrv is set to true, but received port')     if port?

  _buildSocket: ({socket, srvOptions, bufferRate}) =>
    return socket if socket?

    return @_buildSrvSocket({srvOptions, bufferRate}) if srvOptions.resolveSrv
    return @_buildUrlSocket({srvOptions, bufferRate})

  _buildSrvSocket: ({bufferRate, srvOptions}) =>
    @_assertNoUrl _.pick(srvOptions, 'protocol', 'hostname', 'port')

    return new @_BufferedSocket {
      bufferRate: bufferRate
      srvOptions:
        resolveSrv: true
        service: srvOptions.service ? 'meshblu'
        domain:  srvOptions.domain ? 'octoblu.com'
        secure:  srvOptions.secure ? true
        socketIoOptions: srvOptions.socketIoOptions
    }

  _buildUrlSocket: ({bufferRate, srvOptions}) =>
    @_assertNoSrv _.pick(srvOptions, 'service', 'domain', 'secure')
    return new @_BufferedSocket {
      bufferRate: bufferRate
      srvOptions:
        resolveSrv: false
        protocol: srvOptions.protocol ? 'wss'
        hostname: srvOptions.hostname ? 'meshblu-socket-io.octoblu.com'
        port: try parseInt(srvOptions.port ? 443)
        socketIoOptions: srvOptions.socketIoOptions
      }

  _decrypt: ({data}) =>
    return JSON.parse @_privateKey.decrypt data

  _encrypt: ({publicKey, data}) =>
    return new NodeRSA(publicKey).encrypt stableStringify(data), 'base64'

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
