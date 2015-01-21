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

    it 'should have a function called "resetToken"', ->
      expect(@sut.resetToken).to.exist

    describe 'when resetToken is called with a uuid', ->
      beforeEach ->
        @sut.socket.emit = sinon.spy @sut.socket.emit        
      it 'emit resetToken with the uuid', ->
        @sut.resetToken 'uuid'
        expect(@sut.socket.emit).to.have.been.calledWith 'resetToken', uuid: 'uuid'

    describe 'when resetToken is called with a different uuid', ->
      beforeEach ->
        @sut.socket.emit = sinon.spy @sut.socket.emit        
      it 'emit resetToken with the uuid', ->
        @sut.resetToken 'uuid2'
        expect(@sut.socket.emit).to.have.been.calledWith 'resetToken', uuid: 'uuid2'

    describe 'when resetToken is called with an object containing a uuid', ->
      beforeEach ->
        @sut.socket.emit = sinon.spy @sut.socket.emit        
      it 'emit resetToken with the uuid', ->
        @sut.resetToken uuid: 'uuid3'
        expect(@sut.socket.emit).to.have.been.calledWith 'resetToken', uuid:'uuid3'

    describe 'when resetToken is called with a uuid and a callback', ->
      beforeEach ->
        @sut.socket.emit = sinon.spy @sut.socket.emit        
      it 'emit resetToken with the uuid', ->
        @callback = =>
        @sut.resetToken 'uuid4', @callback
        expect(@sut.socket.emit).to.have.been.calledWith 'resetToken', uuid:'uuid4', @callback


