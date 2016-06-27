_              = require 'lodash'
socketIoClient = require 'socket.io-client'

ProxySocket    = require './proxy-socket'
SrvSocket      = require './srv-socket'

DEFAULT_BUFFER_RATE = 100

class BufferedSocket extends ProxySocket
  constructor: ({bufferRate, srvOptions}, dependencies={}) ->
    @_socketIoClient = dependencies.socketIoClient ? socketIoClient
    @_socket = dependencies.socket ? new SrvSocket srvOptions

    @_sendQueue = []
    @_throttledProcessEmitQueue = _.throttle @_processSendQueue, (bufferRate ? DEFAULT_BUFFER_RATE)

    super # Must be called after @_socket is assigned

  connect: (callback) =>
    @_socket.connect callback

  send: =>
    @_sendQueue.push arguments
    @_throttledProcessEmitQueue()

  _processSendQueue: =>
    return if _.isEmpty @_sendQueue

    args = @_sendQueue.shift()
    @_socket.send args...

    _.defer @_throttledProcessEmitQueue

module.exports = BufferedSocket
