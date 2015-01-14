{EventEmitter} = require 'events'
Connection     = require '../../lib/Connection'

describe 'Connection', ->
  describe 'when we pass in a fake socket.io', ->
    beforeEach ->
      @sut = new Connection {}, socketIoClient: -> new EventEmitter

    it 'should instantiate', ->
      expect(@sut).to.exist

    describe 'when connect, then ready, then disconnect', ->
      beforeEach ->
        @socket = @sut.socket
        @socket.emit 'connect'
        @socket.emit 'ready', {uuid: 'cats', token: 'dogs'}
        @socket.emit 'disconnect'

      it 'should emit the uuid and token on identify', (done) ->
        @socket.on 'identity', (config) ->
          expect(config.uuid).to.deep.equal 'cats'
          expect(config.token).to.deep.equal 'dogs'
          done()
        @socket.emit 'identify'
