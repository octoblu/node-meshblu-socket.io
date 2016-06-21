{EventEmitter} = require 'events'
_              = require 'lodash'

DEFAULT_BUFFER_RATE = 100

class BufferedSocket extends EventEmitter
  constructor: ({socketIoClient, uri, bufferRate}) ->
    throw new Error('Missing required argument: socketIoClient') unless socketIoClient?
    throw new Error('Missing required argument: uri') unless uri?

    @_emitStack = []
    @_socketIoClient = socketIoClient
    @_uri = uri
    @_throttledProcessEmitStack = _.throttle @_processEmitStack, (bufferRate ? DEFAULT_BUFFER_RATE)

  connect: (callback) =>
    @_socket = @_socketIoClient(@_uri)
    @_socket.once 'connect', => callback()
    @_socket.on 'identify',  => @emit 'identify', arguments
    @_socket.on 'ready',     => @emit 'ready', arguments

  send: =>
    @_emitStack.push arguments
    @_throttledProcessEmitStack()

  _processEmitStack: =>
    return if _.isEmpty @_emitStack

    args = @_emitStack.shift()
    @_socket.emit args...

    _.defer @_throttledProcessEmitStack

module.exports = BufferedSocket
