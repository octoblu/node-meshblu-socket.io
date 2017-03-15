{beforeEach, describe, it} = global
{expect} = require 'chai'
sinon    = require 'sinon'

{EventEmitter}  = require 'events'
fs              = require 'fs'
stableStringify = require 'json-stable-stringify'
_               = require 'lodash'
NodeRSA         = require 'node-rsa'
path            = require 'path'

PRIVATE_KEY = fs.readFileSync(path.join(__dirname, '../fixtures/private.key')).toString()
PUBLIC_KEY  = fs.readFileSync(path.join(__dirname, '../fixtures/public.key')).toString()
Connection = require '../../'


describe 'Connection', ->
  beforeEach 'construct fake buffered socket', ->
    @socket = new EventEmitter
    @socket.connect = sinon.stub()
    @socket.send    = sinon.stub()
    @socket.close   = sinon.stub()
    @BufferedSocket = sinon.spy => @socket

  describe '->constructor', ->
    describe 'when constructed with !resolveSrv and a domain', ->
      it 'should throw an exception', ->
        construction = => new Connection resolveSrv: false, domain: 'foo.com'
        expect(construction).to.throw 'resolveSrv is set to false, but received domain'

    describe 'when constructed with !resolveSrv and a service', ->
      it 'should throw an exception', ->
        construction = => new Connection resolveSrv: false, service: 'bacon'
        expect(construction).to.throw 'resolveSrv is set to false, but received service'

    describe 'when constructed with !resolveSrv and a secure', ->
      it 'should throw an exception', ->
        construction = => new Connection resolveSrv: false, secure: false
        expect(construction).to.throw 'resolveSrv is set to false, but received secure'

    describe 'when constructed with resolveSrv and a protocol', ->
      it 'should throw an exception', ->
        construction = => new Connection resolveSrv: true, protocol: 'http'
        expect(construction).to.throw 'resolveSrv is set to true, but received protocol'

    describe 'when constructed with resolveSrv and a hostname', ->
      it 'should throw an exception', ->
        construction = => new Connection resolveSrv: true, hostname: 'bacon.biz'
        expect(construction).to.throw 'resolveSrv is set to true, but received hostname'

    describe 'when constructed with resolveSrv and a port', ->
      it 'should throw an exception', ->
        construction = => new Connection resolveSrv: true, port: 443
        expect(construction).to.throw 'resolveSrv is set to true, but received port'

    describe 'when constructed with !resolveSrv and no url params', ->
      it 'construct the BufferedSocket with the url params', ->
        BufferedSocket = sinon.spy(=> new EventEmitter)
        new Connection bufferRate: 1250, resolveSrv: false, auth: {}, {BufferedSocket: BufferedSocket}

        expect(BufferedSocket).to.have.been.calledWithNew
        expect(BufferedSocket).to.have.been.calledWith {
          bufferRate: 1250
          srvOptions:
            resolveSrv: false
            protocol: 'wss'
            hostname: 'meshblu-socket-io.octoblu.com'
            port: 443
            socketIoOptions: undefined
        }

    describe 'when constructed with resolveSrv and no srv params', ->
      it 'construct the BufferedSocket with the srv params', ->
        BufferedSocket = sinon.spy(=> new EventEmitter)
        new Connection bufferRate: 1520, resolveSrv: true, auth: {}, {BufferedSocket: BufferedSocket}

        expect(BufferedSocket).to.have.been.calledWithNew
        expect(BufferedSocket).to.have.been.calledWith {
          bufferRate: 1520
          srvOptions:
            resolveSrv: true
            service: 'meshblu'
            domain: 'octoblu.com'
            secure: true
            socketIoOptions: undefined
        }

    describe 'when constructed with socketio options', ->
      it 'construct the BufferedSocket with the srv params, and the options', ->
        BufferedSocket = sinon.spy(=> new EventEmitter)
        new Connection bufferRate: 1170, options: {forceNew: true}, {BufferedSocket: BufferedSocket}

        expect(BufferedSocket).to.have.been.calledWithNew
        expect(BufferedSocket).to.have.been.calledWith {
          bufferRate: 1170
          srvOptions:
            protocol: 'wss'
            hostname: 'meshblu-socket-io.octoblu.com'
            port: 443
            resolveSrv: false
            socketIoOptions:
              forceNew: true
        }

  describe 'when constructed with a fake BufferedSocket constructor', ->
    beforeEach ->
      @console = error: sinon.spy()
      @sut = new Connection uuid: 'cats', token: 'dogs', auto_set_online: true, privateKey: PRIVATE_KEY, {
        BufferedSocket: @BufferedSocket
        console: @console
      }

    describe 'dealing with readiness', ->
      describe 'when connected', ->
        beforeEach ->
          @sut.connect()
          @socket.emit 'connect'

        it 'should send identity with the uuid and token on identify', ->
          @socket.emit 'identify'
          expect(@socket.send).to.have.been.calledWith 'identity', {
            uuid: 'cats'
            token: 'dogs'
            auto_set_online: true
          }

      describe 'when connect, then ready', ->
        beforeEach ->
          @sut.connect()
          @socket.emit 'ready', {uuid: 'cats', token: 'dogs'}

        describe 'when subscribe is called', ->
          beforeEach ->
            @sut.subscribe uuid: 'this'

          it 'should subscribe to the "this"', ->
            expect(@socket.send).to.have.been.calledWith 'subscribe', uuid: 'this'

        describe 'when subscribed to foo and the socket reconnects', ->
          beforeEach ->
            @sut.subscribe uuid: 'foo'
            @socket.send.reset()
            @socket.emit 'ready', {uuid: 'cats', token: 'dogs'}

          it 'should re-subscribe to the "foo"', ->
            expect(@socket.send).to.have.been.calledWith 'subscribe', uuid: 'foo'

        describe 'when subscribed to foo, unsubscribed, and the socket reconnects', ->
          beforeEach (done) ->
            @sut.subscribe uuid: 'foo'
            @sut.unsubscribe uuid: 'foo'
            @socket.send.reset()

            @socket.emit 'ready', {uuid: 'cats', token: 'dogs'}
            _.delay done, 100

          it 'should not re-subscribe to "foo"', ->
            expect(@socket.send).not.to.have.been.called

    describe '->close', ->
      describe 'when called', ->
        beforeEach (done) ->
          @socket.close.yields()
          @sut.close done

        it 'should call close on the socket', ->
          expect(@socket.close).to.have.been.called

    describe '->device', ->
      describe 'when called', ->
        beforeEach (done) ->
          @socket.send.withArgs('device', {rubegbi: 'Estella Campbell'}).yields(device: {ni: 'Isabelle Dennis'})
          @sut.device {rubegbi: 'Estella Campbell'}, (@result) => done()

        it 'should send device', ->
          expect(@socket.send).to.have.been.calledWith 'device', {rubegbi: 'Estella Campbell'}

        it 'should yield the device result', ->
          expect(@result).to.deep.equal device: {ni: 'Isabelle Dennis'}

    describe '->devices', ->
      describe 'when called', ->
        beforeEach (done) ->
          @socket.send.withArgs('devices', {udpogwak: 'Margaret Cook'}).yields(devices: {ijodovaro: 'Johanna James'})
          @sut.devices {udpogwak: 'Margaret Cook'}, (@result) => done()

        it 'should send devices', ->
          expect(@socket.send).to.have.been.calledWith 'devices', {udpogwak: 'Margaret Cook'}

        it 'should yield the devices result', ->
          expect(@result).to.deep.equal devices: {ijodovaro: 'Johanna James'}

    describe '->encryptMessage', ->
      beforeEach ->
        @sut.getPublicKey = sinon.stub()

      describe 'when getPublicKey yields a public key', ->
        beforeEach ->
          @socket.send.withArgs('getPublicKey', '123').yields null, PUBLIC_KEY

        describe 'when encryptMessage is called with a device of uuid "123"', ->
          beforeEach ->
            @sut.encryptMessage '123', hello: 'world'

          it 'should use the key to encrypted and send a message', ->
            @messageCall = @socket.send.withArgs 'message'
            [event, message] = @messageCall.firstCall.args
            decryptedPayload = JSON.parse new NodeRSA(PRIVATE_KEY).decrypt(message.encryptedPayload).toString()

            expect(@messageCall).to.have.been.calledOnce
            expect(event).to.deep.equal 'message'
            expect(decryptedPayload).to.deep.equal hello: 'world'

      describe 'when getPublicKey yields an error', ->
        beforeEach ->
          @socket.send.withArgs('getPublicKey', '123').yields new Error('uh oh')
          @sut.encryptMessage '123', hello: 'world'

        it 'should call console.error and report the error', ->
          expect(@console.error).to.have.been.calledWith "can't find public key for device"

      describe 'when encryptMessage is called with options and a callback', ->
        beforeEach ->
          @socket.send.withArgs('getPublicKey', '1234').yields null, PUBLIC_KEY
          @callback = ->
          @sut.encryptMessage '1234', 'encrypt-this', payload: 'plain-text', @callback

        it 'should call message with the options and callback', ->
          @messageCall = @socket.send.withArgs 'message'
          [event, message, callback] = @messageCall.firstCall.args
          decryptedPayload = JSON.parse new NodeRSA(PRIVATE_KEY).decrypt(message.encryptedPayload).toString()

          expect(@messageCall).to.have.been.calledOnce
          expect(event).to.deep.equal 'message'
          expect(decryptedPayload).to.deep.equal 'encrypt-this'
          expect(message.payload).to.deep.equal 'plain-text'
          expect(callback).to.equal @callback

      describe 'when encryptMessage is called with no options, but still a callback', ->
        beforeEach ->
          @socket.send.withArgs('getPublicKey', '1234').yields null, PUBLIC_KEY
          @callback = ->
          @sut.encryptMessage '1234', 'encrypt-this', @callback

        it 'should call message with the callback ', ->
          @messageCall = @socket.send.withArgs 'message'
          [event, message, callback] = @messageCall.firstCall.args
          decryptedPayload = JSON.parse new NodeRSA(PRIVATE_KEY).decrypt(message.encryptedPayload).toString()

          expect(@messageCall).to.have.been.calledOnce
          expect(event).to.deep.equal 'message'
          expect(decryptedPayload).to.deep.equal 'encrypt-this'
          expect(callback).to.equal @callback

    describe '->generateAndStoreToken', ->
      describe 'when called', ->
        beforeEach (done) ->
          @socket.send.withArgs('generateAndStoreToken', {uuid: 'Brent Anderson'}).yields({
            uuid: 'Brent Anderson'
            token: 'pig'
          })
          @sut.generateAndStoreToken {uuid: 'Brent Anderson'}, (@result) => done()

        it 'should send generateAndStoreToken', ->
          expect(@socket.send).to.have.been.calledWith 'generateAndStoreToken', {uuid: 'Brent Anderson'}

        it 'should yield the devices result', ->
          expect(@result).to.deep.equal uuid: 'Brent Anderson', token: 'pig'

    describe '->generateKeyPair', ->
      beforeEach ->
        {@privateKey, @publicKey} = @sut.generateKeyPair(8)

      it 'should generate a valid public key', ->
        publicKey = new NodeRSA @publicKey
        expect(publicKey.isPublic()).to.be.true

      it 'should generate a private key', ->
        privateKey = new NodeRSA @privateKey
        expect(privateKey.isPrivate()).not.to.be.false # isPrivate returns false or a BigInt() if true

    describe '->message', ->
      describe 'when message is called the old way, with one big object', ->
        beforeEach ->
          @callback = sinon.spy()
          @sut.message {devices: ['456'], payload: {hello: 'world'}}, @callback

        it 'should call send "message" with an object a devices and payload property', ->
          expectedMessage = {devices: ['456'], payload: {hello: 'world'}}
          expect(@socket.send).to.have.been.calledWith 'message', expectedMessage, @callback

    describe '->register', ->
      describe 'when called', ->
        beforeEach (done) ->
          @socket.send.withArgs('register', {ni: 'Augusta Frank'}).yields 'guk'
          @sut.register {ni: 'Augusta Frank'}, (@result) => done()

        it 'should send register', ->
          expect(@socket.send).to.have.been.calledWith 'register', {ni: 'Augusta Frank'}

        it 'should yield the register result', ->
          expect(@result).to.deep.equal 'guk'

    describe '->resetToken', ->
      describe 'when resetToken is called with a uuid', ->
        beforeEach ->
          @sut.resetToken 'uuid'

        it 'should send resetToken with the uuid', ->
          expect(@socket.send).to.have.been.calledWith 'resetToken', uuid: 'uuid'

      describe 'when resetToken is called with a different uuid', ->
        beforeEach ->
          @sut.resetToken 'uuid2'

        it 'emit resetToken with the uuid', ->
          expect(@socket.send).to.have.been.calledWith 'resetToken', uuid: 'uuid2'

      describe 'when resetToken is called with an object containing a uuid', ->
        beforeEach ->
          @sut.resetToken uuid: 'uuid3'

        it 'emit resetToken with the uuid', ->
          expect(@socket.send).to.have.been.calledWith 'resetToken', uuid: 'uuid3'

      describe 'when resetToken is called with a uuid and a callback', ->
        beforeEach ->
          @callback = ->
          @sut.resetToken 'uuid4', @callback

        it 'emit resetToken with the uuid', ->
          expect(@socket.send).to.have.been.calledWith 'resetToken', uuid:'uuid4', @callback

    describe '->revokeToken', ->
      describe 'when called', ->
        beforeEach (done) ->
          @socket.send.withArgs('revokeToken', {uuid: 'pat'}).yields()
          @sut.revokeToken {uuid: 'pat'}, (@result) => done()

        it 'should send revokeToken', ->
          expect(@socket.send).to.have.been.calledWith 'revokeToken', {uuid: 'pat'}

    describe '->revokeTokenByQuery', ->
      describe 'when called', ->
        beforeEach (done) ->
          @socket.send.withArgs('revokeTokenByQuery', {uuid: 'pat', tag: 'hi'}).yields()
          @sut.revokeTokenByQuery {uuid: 'pat', tag: 'hi'}, (@result) => done()

        it 'should send revokeTokenByQuery', ->
          expect(@socket.send).to.have.been.calledWith 'revokeTokenByQuery', {uuid: 'pat', tag: 'hi'}


    describe '->sign', ->
      describe 'when it is called with a string', ->
        it 'should sign', ->
          signature = @sut.sign 'doesntmatter'
          verification = new NodeRSA(PUBLIC_KEY).verify stableStringify('doesntmatter'), signature, 'utf8', 'base64'
          expect(verification).to.be.true

      describe 'when it is called with an object', ->
        it 'should sign a stable string version of that data', ->
          signature = @sut.sign hair: 'blue', eyes: 'brown'
          dataStr = stableStringify(hair: 'blue', eyes: 'brown')
          verification = new NodeRSA(PUBLIC_KEY).verify dataStr, signature, 'utf8', 'base64'
          expect(verification).to.be.true

    describe '->subscribe', ->
      describe 'when called with a uuid', ->
        beforeEach ->
          @sut.subscribe 'kozunfez'

        it 'should send subscribe with the uuid wrapped in an object', ->
          expect(@socket.send).to.have.been.calledWith 'subscribe', uuid: 'kozunfez'

      describe 'when called with an object', ->
        beforeEach ->
          @sut.subscribe uuid: 'upa'

        it 'should send subscribe with the uuid wrapped in an object', ->
          expect(@socket.send).to.have.been.calledWith 'subscribe', uuid: 'upa'

    describe '->unregister', ->
      describe 'when called', ->
        beforeEach (done) ->
          @socket.send.withArgs('unregister', {uuid: 'ruko'}).yields 'tas'
          @sut.unregister {uuid: 'ruko'}, (@result) => done()

        it 'should send unregister', ->
          expect(@socket.send).to.have.been.calledWith 'unregister', {uuid: 'ruko'}

        it 'should yield the unregister result', ->
          expect(@result).to.deep.equal 'tas'

    describe '->unsubscribe', ->
      describe 'when called with a uuid', ->
        beforeEach ->
          @sut.unsubscribe 'kozunfez'

        it 'should send unsubscribe with the uuid wrapped in an object', ->
          expect(@socket.send).to.have.been.calledWith 'unsubscribe', uuid: 'kozunfez'

      describe 'when called with an object', ->
        beforeEach ->
          @sut.unsubscribe uuid: 'upa'

        it 'should send unsubscribe with the uuid wrapped in an object', ->
          expect(@socket.send).to.have.been.calledWith 'unsubscribe', uuid: 'upa'

    describe '->update', ->
      describe 'when called', ->
        beforeEach (done) ->
          @socket.send.withArgs('update', {dap: 'Dustin Waters'}).yields({gawehemeh: 'Melvin Reynolds'})
          @sut.update {dap: 'Dustin Waters'}, (@result) => done()

        it 'should send update', ->
          expect(@socket.send).to.have.been.calledWith 'update', {dap: 'Dustin Waters'}

        it 'should yield the update result', ->
          expect(@result).to.deep.equal gawehemeh: 'Melvin Reynolds'

    describe '->verify', ->
      describe 'when it is called with data and a valid signature', ->
        it 'should return true', ->
          signature = new NodeRSA(PRIVATE_KEY).sign stableStringify('foo'), 'base64'
          expect(@sut.verify 'foo', signature).to.be.true

      describe 'when it is called with data and an invalid signature', ->
        it 'should call NodeRSA#verify', ->
          expect(@sut.verify 'foo', 'definitely-forged').to.be.false

    describe '->whoami', ->
      describe 'when called', ->
        beforeEach (done) ->
          @socket.send.withArgs('whoami', {}).yields {you: 'Lloyd Reese'}
          @sut.whoami (@result) => done()

        it 'should send whoami', ->
          expect(@socket.send).to.have.been.calledWith 'whoami', {}

        it 'should yield whoami the result', ->
          expect(@result).to.deep.equal you: 'Lloyd Reese'

    describe 'on "config"', ->
      describe 'when we receive a config event', ->
        beforeEach (done) ->
          @sut.once 'config', (@config) => done()
          @socket.emit 'config', za: 'lulivop'

        it 'should re-emit it on "config"', ->
          expect(@config).to.deep.equal za: 'lulivop'

    describe 'on "message"', ->
      describe 'when we receive a message', ->
        beforeEach (done) ->
          @sut.once 'message', (@message) =>
            done()

          @socket.emit 'message', payload: foo: 'bar'

        it 'should emit only once', ->
          expect(@message.payload).to.deep.equal foo: 'bar'

      describe 'when we receive a message with an "encryptedPayload" property', ->
        beforeEach (done) ->
          @sut.once 'message', (@message) => done()

          encryptedPayload = new NodeRSA(PUBLIC_KEY).encrypt stableStringify('foo'), 'base64'
          @socket.emit 'message', {encryptedPayload}

        it 'should emit the decrypted payload under the encryptedPayload key', ->
          expect(@message.encryptedPayload).to.deep.equal 'foo'

      describe 'when we get a message with a different value for "encryptedPayload"', ->
        beforeEach (done) ->
          @sut.once 'message', (@message) => done()

          encryptedPayload = new NodeRSA(PUBLIC_KEY).encrypt stableStringify('world!'), 'base64'
          @socket.emit 'message', {encryptedPayload}

        it 'should emit the decrypted payload under the encryptedPayload key', ->
          expect(@message.encryptedPayload).to.deep.equal 'world!'

      describe 'when the encrypted payload is a json object', ->
        beforeEach (done) ->
          @sut.once 'message', (@message) => done()

          encryptedPayload = new NodeRSA(PUBLIC_KEY).encrypt stableStringify(foo: 'bar'), 'base64'
          @socket.emit 'message', {encryptedPayload}

        it 'should emit the decrypted payload under the encryptedPayload key', ->
          expect(@message.encryptedPayload).to.deep.equal foo: 'bar'

    describe 'on "ratelimited"', ->
      beforeEach (done) ->
        @sut.once 'ratelimited', (@data) => done()
        @socket.emit 'ratelimited', foo: 'bar'

      it 'should emit the rate limited message', ->
        expect(@data).to.deep.equal foo: 'bar'
