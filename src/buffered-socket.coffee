_              = require 'lodash'

ProxySocket    = require './proxy-socket'

DEFAULT_BUFFER_RATE = 100

class BufferedSocket extends ProxySocket
  constructor: ({bufferRate, srvOptions}, dependencies={}) ->
    ReconnectSocket = dependencies.ReconnectSocket ? require './reconnect-socket'
    @_socket = new ReconnectSocket {srvOptions}

    @_sendQueue = []
    @_throttledProcessEmitQueue = _.throttle @_processSendQueue, (bufferRate ? DEFAULT_BUFFER_RATE)

    super # Must be called after @_socket is assigned

  close: (callback) =>
    @_socket.close callback

  connect: (callback) =>
    throw new Error 'connect should not take a callback' if callback?
    @_socket.connect()

  send: =>
    @_sendQueue.push arguments
    @_throttledProcessEmitQueue()

  _processSendQueue: =>
    return if _.isEmpty @_sendQueue

    args = @_sendQueue.shift()
    @_socket.send args...

    _.defer @_throttledProcessEmitQueue

module.exports = BufferedSocket
