{EventEmitter} = require 'events'
Connection     = require '../../lib/Connection'

describe 'Connection', ->
  describe 'when we pass in a fake socket.io', ->
    beforeEach ->
      @console = error: sinon.spy()
      @sut = new Connection( {}, {
        socketIoClient: -> new EventEmitter(),
        console: @console
      })

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


    describe 'encryptMessage', ->
      it 'should exist', ->
        expect(@sut.encryptMessage).to.exist

      beforeEach ->
        @sut.getPublicKey = sinon.stub()

      describe 'when encryptMessage is called with a device of uuid 1', ->
        it 'should call getPublicKey', ->
          @sut.encryptMessage devices: 1
          expect(@sut.getPublicKey).to.have.been.called

        it 'should call getPublicKey with the uuid of the target device 1', ->
          @sut.encryptMessage devices: 1
          expect(@sut.getPublicKey).to.have.been.calledWith 1

        describe 'when getPublicKey returns with a public key', ->
          beforeEach ->
            @publicKey = encrypt: sinon.stub()
            @sut.getPublicKey.yields null, @publicKey

          it 'should call encrypt on the response from getPublicKey', ->
            @sut.encryptMessage devices: 1, payload : { hello : 'world' }
            expect(@publicKey.encrypt).to.have.been.calledWith JSON.stringify(hello : 'world')

          describe 'when publicKey.encrypt returns with "12345"', ->
            beforeEach ->
              @sut.message = sinon.spy(@sut.message)
              @publicKey.encrypt.returns '12345'

            it 'should call message with an encrypted payload', ->
              @sut.encryptMessage devices: 1, payload : { hello : 'world' }
              expect(@sut.message).to.have.been.calledWith devices: 1, encryptedPayload: '12345'


        describe 'when getPublicKey returns with an error', ->
          beforeEach ->
            @sut.getPublicKey.yields true, null

          it 'should call console.error and report the error', ->
            @sut.encryptMessage devices: 1, payload : { hello : 'world' }
            expect(@console.error).to.have.been.calledWith 'can\'t find public key for device'


      describe 'when encryptMessage is called with a different uuid', ->
        it 'should call getPublicKey with the uuid of the target device', ->
          @sut.encryptMessage devices: 2
          expect(@sut.getPublicKey).to.have.been.calledWith 2


