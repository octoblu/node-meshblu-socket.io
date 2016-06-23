{beforeEach, describe, it} = global
{expect} = require 'chai'
sinon    = require 'sinon'

{EventEmitter} = require 'events'
fs             = require 'fs'
_              = require 'lodash'
NodeRSA        = require 'node-rsa'
path           = require 'path'

Connection     = require '../../src/connection'

describe 'Connection', ->

  describe.only '-> connect', ->
    describe 'when instantiated with a protocol, hostname, and port', ->
      beforeEach (done) ->
        @socket = new EventEmitter()
        @socketIoClient = sinon.spy(=> @socket)

        @sut = new Connection protocol: 'wss', hostname: 'meshblu.octoblu.com', port: 443, {
          socketIoClient: @socketIoClient
          console: @console
        }
        @sut.connect done
        @socket.emit 'connect'

      it 'should instantiate the socket client with the url', ->
        expect(@socketIoClient).to.have.been.calledWith 'wss://meshblu.octoblu.com:443'

    describe 'when instantiated with a service, domain, resolveSrv, and dns lookup succeeds', ->
      beforeEach (done) ->
        @socket = new EventEmitter()
        @socketIoClient = sinon.spy(=> @socket)
        @resolveSrv = sinon.stub().withArgs('_meshblu._socket-io-wss.octoblu.test').yields null, [{
          piority: 1
          weight: 1
          port: 443
          name: 'meshblu-socket-io.octoblu.test'
        }]


        @sut = new Connection service: 'meshblu', domain: 'octoblu.test', resolveSrv: true, {
          socketIoClient: @socketIoClient
          console: @console
          dns: {resolveSrv: @resolveSrv}
        }
        @sut.connect done
        @socket.emit 'connect'

      it 'should instantiate the socket client with the resolved service hostname and port', ->
        expect(@socketIoClient).to.have.been.calledWith 'wss://meshblu-socket-io.octoblu.test:443'

  describe 'when we pass in a fake socket.io', ->
    beforeEach ->
      @socket = new EventEmitter()

      @console = error: sinon.spy()
      @sut = new Connection uuid: 'cats', token: 'dogs', {
        socketIoClient: => @socket
        console: @console
      }

    it 'should instantiate', ->
      expect(@sut).to.exist

    it 'should have a function called "resetToken"', ->
      expect(@sut.resetToken).to.be.a 'function'

    describe 'when connected', ->
      beforeEach (done) ->
        @sut.connect done
        @socket.emit 'connect'

      it 'should emit the uuid and token on identify', (done) ->
        @socket.on 'identity', (config) ->
          expect(config.uuid).to.deep.equal 'cats'
          expect(config.token).to.deep.equal 'dogs'
          done()
        @socket.emit 'identify'

    describe 'when connect, then ready', ->
      beforeEach (done) ->
        @sut.connect done
        @socket.emit 'connect'
        @socket.emit 'ready', {uuid: 'cats', token: 'dogs'}

      describe 'when subscribe and the socket reconnects', ->
        beforeEach ->
          @onSubscribeSpy = sinon.spy()
          @socket.on 'subscribe', @onSubscribeSpy

          @sut.subscribe uuid: 'this'

        it 'should re subscribe to the "this"', ->
          expect(@onSubscribeSpy).to.have.been.calledWith uuid: 'this'

      describe 'when subscribed to foo and the socket reconnects', ->
        beforeEach (done) ->
          @sut.subscribe uuid: 'foo'

          @onSubscribeSpy = sinon.spy()
          @socket.on 'subscribe', @onSubscribeSpy
          @socket.once 'subscribe', => done()
          @socket.emit 'ready', {uuid: 'cats', token: 'dogs'}

        it 'should re subscribe to the "foo"', ->
          expect(@onSubscribeSpy).to.have.been.calledWith uuid: 'foo'

      describe 'when subscribed to foo, unsubscribed, and the socket reconnects', ->
        beforeEach (done) ->
          @socket.once 'subscribe', => done()
          @sut.subscribe uuid: 'foo'

        beforeEach (done) ->
          @socket.once 'unsubscribe', => done()
          @sut.unsubscribe uuid: 'foo'

        beforeEach (done) ->
          @onSubscribeSpy = sinon.spy()

          @socket.on 'subscribe', @onSubscribeSpy
          @socket.emit 'ready', {uuid: 'cats', token: 'dogs'}
          _.delay done, 100

        it 'should not re subscribe to "foo"', ->
          expect(@onSubscribeSpy).not.to.have.been.called

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
      beforeEach ->
        @sut.getPublicKey = sinon.stub()

      describe 'when encryptMessage is called with a device of uuid 1', ->
        it 'should call getPublicKey', ->
          @sut.encryptMessage 1
          expect(@sut.getPublicKey).to.have.been.called

        it 'should call getPublicKey with the uuid of the target device 1', ->
          @sut.encryptMessage 1
          expect(@sut.getPublicKey).to.have.been.calledWith 1

        describe 'when getPublicKey returns with a public key', ->
          beforeEach ->
            @sut.message = sinon.stub()
            @publicKey = {encrypt: sinon.stub().returns('54321')}
            @sut.getPublicKey.yields null, @publicKey

          it 'should call encrypt on the response from getPublicKey', ->
            @sut.encryptMessage 1, hello : 'world'
            expect(@publicKey.encrypt).to.have.been.calledWith JSON.stringify(hello : 'world')

          describe 'when publicKey.encrypt returns with a buffer of "12345"', ->
            beforeEach ->
              @publicKey.encrypt.returns new Buffer '12345',

            it 'should call message with an encrypted payload', ->
              @sut.encryptMessage 1, hello : 'world'
              expect(@sut.message).to.have.been.calledWith 1, null, encryptedPayload: 'MTIzNDU='

        describe 'when getPublicKey returns with an error', ->
          beforeEach ->
            @sut.getPublicKey.yields true, null

          it 'should call console.error and report the error', ->
            @sut.encryptMessage 1, { hello : 'world' }
            expect(@console.error).to.have.been.calledWith 'can\'t find public key for device'

      describe 'when encryptMessage is called with a different uuid', ->
        it 'should call getPublicKey with the uuid of the target device', ->
          @sut.encryptMessage 2
          expect(@sut.getPublicKey).to.have.been.calledWith 2

      describe 'when encryptMessage is called with options', ->
        beforeEach ->
          @uuid = '54063a2f-fcfb-4f97-8438-f8b0b0c635ad'
          @callback = =>
          @options = payload: 'plain-text'

          @publicKey = {encrypt: sinon.stub().returns('54321')}
          @sut.getPublicKey.yields null, @publicKey
          @sut.message = sinon.stub()
          @sut.encryptMessage @uuid, 'encrypt-this', @options, @callback

        it 'should call message with the options ', ->
          expectedOptions = {payload: 'plain-text', encryptedPayload: '54321'}
          expect(@sut.message).to.have.been.calledWith @uuid, null, expectedOptions, @callback

    describe 'sign', ->
      beforeEach ->
        @sut.privateKey =  sign: sinon.stub()
        @sut.privateKey.sign.returns new Buffer( 'cafe', 'base64')

      it 'should exist', ->
        expect(@sut.sign).to.exist

      describe 'when it is called with a string', ->
        it 'should call NodeRSA#sign', ->
          @sut.sign 'doesntmatter'
          expect(@sut.privateKey.sign).to.have.been.calledWith '"doesntmatter"'

      describe 'when it is called with a different string', ->
        it 'should call NodeRSA#sign', ->
          @sut.sign 'matters,doesnt'
          expect(@sut.privateKey.sign).to.have.been.calledWith '"matters,doesnt"'

      describe 'when it is called with an object', ->
        it 'should call privateKey.sign with a string version of that data', ->
          @objToSign = hair: 'blue', eyes: 'brown'
          @sut.sign @objToSign
          expect(@sut.privateKey.sign).to.have.been.calledWith '{"eyes":"brown","hair":"blue"}'

      describe 'when privateKey.sign returns a buffer', ->
        it 'should return the base64-encoded version of that buffer', ->
          @sut.privateKey.sign.returns new Buffer( 'deadbeef', 'base64')
          expect( @sut.sign 'whatever' ).to.equal 'deadbeef'

      describe 'when privateKey.sign returns a different buffer', ->
        it 'should return the base64-encoded version of that buffer', ->
          @sut.privateKey.sign.returns new Buffer( 'decafec0ffee', 'base64')
          expect( @sut.sign 'whatever' ).to.equal 'decafec0ffee'

    describe 'verify', ->
      beforeEach ->
        @sut.privateKey =  verify: sinon.stub()
      it 'should exist', ->
        expect(@sut.verify).to.exist

      describe 'when it is called with data and a signature', ->
        it 'should call NodeRSA#verify', ->
          @sut.verify 'somedata', 'af0d1'
          expect(@sut.privateKey.verify).to.have.been.calledWith '"somedata"' ,'af0d1', 'utf8', 'base64'

      describe 'when it is called with data and a signature', ->
        it 'should call NodeRSA#verify', ->
          @sut.verify 'moardata', 'b0fd3'
          expect(@sut.privateKey.verify).to.have.been.calledWith '"moardata"' ,'b0fd3', 'utf8', 'base64'

      describe 'when publicKey.verify returns true', ->
        it 'should return true', ->
          @sut.privateKey.verify.returns true
          expect(@sut.verify()).to.be.true

      describe 'when publicKey.verify returns false', ->
        it 'should return false', ->
          @sut.privateKey.verify.returns false
          expect(@sut.verify()).to.be.false

    describe 'getPublicKey', ->
      it 'should exist', ->
        expect(@sut.getPublicKey).to.exist

      describe 'when called', ->
        beforeEach () ->
          @sut.socket.emit = sinon.stub()
          @callback = sinon.spy()

        it 'should call device on itself with the uuid of the device we are getting the key for', ->
          @sut.getPublicKey 'c9707ff2-b3e7-4363-b164-90f5753dac68', @callback
          expect(@sut.socket.emit).to.have.been.calledWith 'getPublicKey', 'c9707ff2-b3e7-4363-b164-90f5753dac68'

        describe 'when called with a different uuid', ->
          it 'should call device with the different uuid', ->
            @sut.getPublicKey '4df5ee81-8f60-437d-8c19-2375df745b70', @callback
            expect(@sut.socket.emit).to.have.been.calledWith 'getPublicKey', '4df5ee81-8f60-437d-8c19-2375df745b70'

          describe 'when device returns an invalid device', ->
            beforeEach ->
              @sut.socket.emit.yields new Error('you suck'), null

            it 'should call the callback with an error', ->
              @sut.getPublicKey 'c9707ff2-b3e7-4363-b164-90f5753dac68', @callback
              error = @callback.args[0][0]
              expect(error).to.exist

          describe 'when device returns a valid device without a public key', ->
            beforeEach ->
              @sut.socket.emit.yields null, null

            it 'should call the callback with an error', ->
              @sut.getPublicKey 'c9707ff2-b3e7-4363-b164-90f5753dac68', @callback
              error = @callback.args[0][0]
              expect(error).to.exist

          describe 'when device returns a valid device with a public key', ->
            beforeEach ->
              @publicKey = fs.readFileSync path.join(__dirname, 'public.key')
              @privateKey = new NodeRSA fs.readFileSync path.join(__dirname, 'private.key')
              @sut.socket.emit.yields null, @publicKey

            it 'should call the callback without an error', ->
              @sut.getPublicKey 'c9707ff2-b3e7-4363-b164-90f5753dac68', @callback
              error = @callback.args[0][0]
              expect(error).to.not.exist

            it 'should only call the callback once', ->
              @sut.getPublicKey 'c9707ff2-b3e7-4363-b164-90f5753dac68', @callback
              expect(@callback.calledOnce).to.be.true

            it 'should return an object with a method encrypt', ->
              @sut.getPublicKey 'c9707ff2-b3e7-4363-b164-90f5753dac68', @callback
              key = @callback.args[0][1]
              expect(key.encrypt).to.exist

            describe 'when encrypt is called with a message on the returned key', ->
              beforeEach ->
                @sut.getPublicKey 'c9707ff2-b3e7-4363-b164-90f5753dac68', @callback
                key = @callback.args[0][1]
                @encryptedMessage = key.encrypt('hi').toString 'base64'

              it 'should be able to decrypt the result with the private key', ->
                decryptedMessage = @privateKey.decrypt(@encryptedMessage).toString()
                expect(decryptedMessage).to.equal 'hi'

      describe 'generateKeyPair', ->
        beforeEach ->
          class FakeNodeRSA
            generateKeyPair: sinon.spy()
            exportKey: (arg) => {public: 'the-public', private: 'the-private'}[arg]

          @nodeRSA = new FakeNodeRSA()

          @sut = new Connection {}, {
            socketIoClient: -> new EventEmitter(),
            console: @console
            NodeRSA: => @nodeRSA
          }
          @result = @sut.generateKeyPair()

        it 'should have called generateKeyPair on an instance of nodeRSA', ->
          expect(@nodeRSA.generateKeyPair).to.have.been.called

        it 'should generate a public key', ->
          expect(@result.publicKey).to.equal 'the-public'

        it 'should generate a private key', ->
          expect(@result.privateKey).to.equal 'the-private'

    describe 'when we create a connection with a private key', ->
      beforeEach ->
        @console = error: sinon.spy()
        @privateKey = fs.readFileSync path.join(__dirname, 'private.key')
        @sut = new Connection( { privateKey: @privateKey }, {
          socketIoClient: -> new EventEmitter(),
          console: @console
        })


      it 'should create a private key property on itself', ->
        expect(@sut.privateKey).to.exist;

      it 'should have a private key property that is based on the key passed in', ->
        expect(@sut.privateKey.exportKey('private')).to.equal @privateKey

      describe 'when we get a message with an "encryptedPayload" property', ->
        beforeEach ->
          @sut.privateKey.decrypt = sinon.stub().returns null

        it 'should decrypt the encryptedPayload', ->
          @sut._handleAckRequest 'message', encryptedPayload: 'hello!'
          expect(@sut.privateKey.decrypt).to.be.calledWith 'hello!'

      describe 'when we get a message with a different value for "encryptedPayload"', ->
        beforeEach ->
          @sut.privateKey.decrypt = sinon.stub().returns null

        it 'should decrypt that encryptedPayload', ->
          @sut._handleAckRequest 'message', encryptedPayload: 'world!'
          expect(@sut.privateKey.decrypt).to.be.calledWith 'world!'

      describe 'when the privatekey decrypts the payload', ->
        beforeEach ->
          @sut.privateKey.decrypt = sinon.stub().returns 5
          sinon.stub @sut, 'emit'

        it 'should assign the decrypted payload to the message before emitting it', ->
          @sut._handleAckRequest 'message', encryptedPayload: 'world!'
          expect(@sut.emit.args[0][1]).to.deep.equal( decryptedPayload: 5, encryptedPayload: 'world!' )

      describe 'when the privatekey decrypts a different encryptedPayload', ->
        beforeEach ->
          @sut.privateKey.decrypt = sinon.stub().returns 10
          sinon.stub @sut, 'emit'

        it 'should assign the decrypted payload to the message before emitting it', ->
          @sut._handleAckRequest 'message', encryptedPayload: 'hello!'
          expect(@sut.emit.args[0][1]).to.deep.equal( decryptedPayload: 10, encryptedPayload: 'hello!' )

      describe 'when the encrypted payload is a json object', ->
        beforeEach ->
          @sut.privateKey.decrypt = sinon.stub().returns '{"foo": "bar"}'
          sinon.stub @sut, 'emit'

        it 'should parse the json', ->
          @sut._handleAckRequest 'message', encryptedPayload: 'world!'
          expect(@sut.emit.args[0][1]).to.deep.equal( decryptedPayload: {"foo": "bar"}, encryptedPayload: 'world!' )

    describe 'message', ->
      beforeEach ->
        @sut._emitWithAck = sinon.stub()

      describe 'when message is called with a uuid and a message body', ->
        it 'should call emitWithAck with an object with a devices and payload property', ->
          @object = {}
          @sut.message 1, @object
          messageObject = @sut._emitWithAck.args[0][1]
          expect(messageObject).to.deep.equal {devices: 1, payload: @object}

      describe 'when message is called with a different uuid and message body', ->
        it 'should call emitWithAck with an object with that uuid and payload', ->
          @object = hello: 'world'
          @sut.message 2, @object
          messageObject = @sut._emitWithAck.args[0][1]
          expect(messageObject).to.deep.equal {devices: 2, payload: @object}

      describe 'when message is called with a callback', ->
        it 'should call emitWithAck with a callback', ->
          @callback = sinon.spy()
          @object = {}
          @sut.message 1, @object, @callback
          passedCallback = @sut._emitWithAck.args[0][2]
          expect(passedCallback).to.equal @callback

      describe 'when message is called the old way, with one big object', ->
        it 'should call _emitWithAck with the entire object and a callback', ->
          callback = sinon.spy()
          message = {devices: [ 1 ], payload: { hello: 'world' }}
          @sut.message message, callback

          expect(@sut._emitWithAck).to.have.been.calledWith 'message', message, callback

      describe 'when message is called with options', ->
        it 'should call _emitWithAck with an object with the options in it', ->
          callback = sinon.spy()
          message = cats: true
          options = hello: 'world'
          messageObject = {
            devices: [1],
            payload:
              cats: true,
            hello: 'world'
          }
          @sut.message [1], message, options, callback

          emitArgs = @sut._emitWithAck.args[0]
          expect(emitArgs[1]).to.deep.equal messageObject
