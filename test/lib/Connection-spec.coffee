{EventEmitter} = require 'events'
Connection     = require '../../lib/Connection'
NodeRSA = require 'node-rsa'

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

    describe 'when connect, then ready', ->
      beforeEach ->
        @socket = @sut.socket
        @socket.emit 'connect'
        @socket.emit 'ready', {uuid: 'cats', token: 'dogs'}

      describe 'when subscribe and the socket reconnects', ->
        beforeEach ->
          @sut.bufferedSocketEmit = sinon.spy()
          @sut.subscribe uuid: 'this'
          sinon.spy @sut.socket, 'emit'
          @socket.emit 'ready', {uuid: 'cats', token: 'dogs'}

        it 'should re subscribe to the "this"', ->
          expect(@sut.bufferedSocketEmit).to.have.been.calledWith 'subscribe', uuid: 'this'

      describe 'when subscribed to foo and the socket reconnects', ->
        beforeEach ->
          @sut.bufferedSocketEmit = sinon.spy()
          @sut.subscribe uuid: 'foo'
          sinon.spy @sut.socket, 'emit'
          @socket.emit 'ready', {uuid: 'cats', token: 'dogs'}

        it 'should re subscribe to the "this"', ->
          expect(@sut.bufferedSocketEmit).to.have.been.calledWith 'subscribe', uuid: 'foo'

      describe 'when subscribed to foo, unsubscribed, and the socket reconnects', ->
        beforeEach ->
          @sut.subscribe uuid: 'foo'
          @sut.unsubscribe uuid: 'foo'
          sinon.spy @sut.socket, 'emit'
          @socket.emit 'ready', {uuid: 'cats', token: 'dogs'}

        it 'should re subscribe to the "this"', ->
          expect(@socket.emit).not.to.have.been.calledWith 'subscribe', uuid: 'foo'

    it 'should have a function called "resetToken"', ->
      expect(@sut.resetToken).to.exist

    describe '-> parseUrl', ->
      beforeEach ->
        @sut = new Connection( {}, {
          socketIoClient: -> new EventEmitter(),
          console: @console
          })

      describe 'when nil', ->
        it 'should return nothing', ->
          console.log(@sut.parseUrl)
          expect(@sut.parseUrl()).to.be.null

      describe 'when given an empty string', ->
        it 'should return nothing', ->
          expect(@sut.parseUrl('')).to.be.null

      describe 'when given a web socket URL', ->
        it 'should return a url', ->
          expect(@sut.parseUrl('ws://something.co')).to.equal('ws://something.co')

      describe 'when given an http URL', ->
        it 'should return a websocket url', ->
          expect(@sut.parseUrl('http://something.co')).to.equal('ws://something.co/')

      describe 'when given a wss URL', ->
        it 'should return a wss url', ->
          expect(@sut.parseUrl('wss://something.co')).to.equal('wss://something.co')

      describe 'when given an https URL', ->
        it 'should return a secure websocket url', ->
          expect(@sut.parseUrl('https://something.co')).to.equal('wss://something.co/')

      describe 'when given a url with a hostname and no protocol', ->
        it 'should return a websocket url', ->
          expect(@sut.parseUrl('something.co')).to.equal('ws://something.co')

      describe 'when given a url with a hostname and a port', ->
        it 'should return a secure websocket url', ->
          expect(@sut.parseUrl('something.co', 443)).to.equal('wss://something.co:443')

      describe 'when given a url with a hostname and a custom port', ->
        it 'should return a websocket url with the port', ->
          expect(@sut.parseUrl('http://something.co', 333)).to.equal('ws://something.co:333/')

      describe 'when given a url with a url with port, and a custom port', ->
        it 'should return a websocket url with the port', ->
          expect(@sut.parseUrl('http://something.co:443', 555)).to.equal('ws://something.co:555/')

      describe 'when given a url with a url with port, and a ssl port as a string', ->
        it 'should return a websocket url with the port', ->
          expect(@sut.parseUrl('ws://something.co', '443')).to.equal('wss://something.co:443')

      describe 'when given a url with a url with port, and an invalid port as a string', ->
        it 'should return a websocket url with the port', ->
          expect(@sut.parseUrl('ws://something.co', 'jjk')).to.equal('ws://something.co')

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
          expect(@sut.message).to.have.been.calledWith @uuid, null, {payload: 'plain-text', encryptedPayload: '54321'}, @callback

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
              @publicKey = '-----BEGIN PUBLIC KEY-----\nMFswDQYJKoZIhvcNAQEBBQADSgAwRwJAX9eHOOux3ycXbc/FVzM+z9OQeouRePWA\nT0QRcsAHeDNy4HwNrME7xxI2LH36g8H3S+zCapYYdCyc1LwSDEAfcQIDAQAB\n-----END PUBLIC KEY-----'

              @privateKey = new NodeRSA '-----BEGIN RSA PRIVATE KEY-----\nMIIBOAIBAAJAX9eHOOux3ycXbc/FVzM+z9OQeouRePWAT0QRcsAHeDNy4HwNrME7\nxxI2LH36g8H3S+zCapYYdCyc1LwSDEAfcQIDAQABAkA+59C6PIDvzdGj4rZM6La2\nY881j7u4n7JK1It7PKzqaFPzY+Aee0tRp1kOF8+/xOG1NGYLFyYBbCM38bnjnkwB\nAiEAqzkA7zUZl1at5zoERm9YyV/FUntQWBYCvdWS+5U7G8ECIQCPS8hY8yZwOL39\n8JuCJl5TvkGRg/w3GFjAo1kwJKmvsQIgNoRw8rlCi7hSqNQFNnQPnha7WlbfLxzb\nBJyzLx3F80ECIGjiPi2lI5BmZ+IUF67mqIpBKrr40UX+Yw/1QBW18CGxAiBPN3i9\nIyTOw01DUqSmXcgrhHJM0RogYtJbpJkT6qbPXw==\n-----END RSA PRIVATE KEY-----'
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

          @sut = new Connection( {}, {
            socketIoClient: -> new EventEmitter(),
            console: @console
            NodeRSA: => @nodeRSA
          });
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
        @privateKey = '-----BEGIN RSA PRIVATE KEY-----\nMIIBOAIBAAJAX9eHOOux3ycXbc/FVzM+z9OQeouRePWAT0QRcsAHeDNy4HwNrME7\nxxI2LH36g8H3S+zCapYYdCyc1LwSDEAfcQIDAQABAkA+59C6PIDvzdGj4rZM6La2\nY881j7u4n7JK1It7PKzqaFPzY+Aee0tRp1kOF8+/xOG1NGYLFyYBbCM38bnjnkwB\nAiEAqzkA7zUZl1at5zoERm9YyV/FUntQWBYCvdWS+5U7G8ECIQCPS8hY8yZwOL39\n8JuCJl5TvkGRg/w3GFjAo1kwJKmvsQIgNoRw8rlCi7hSqNQFNnQPnha7WlbfLxzb\nBJyzLx3F80ECIGjiPi2lI5BmZ+IUF67mqIpBKrr40UX+Yw/1QBW18CGxAiBPN3i9\nIyTOw01DUqSmXcgrhHJM0RogYtJbpJkT6qbPXw==\n-----END RSA PRIVATE KEY-----'
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
