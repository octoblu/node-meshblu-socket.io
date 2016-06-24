{beforeEach, describe, it} = global
{expect} = require 'chai'
sinon = require 'sinon'

{EventEmitter}  = require 'events'
BufferedSocket  = require '../../src/buffered-socket'
AsymetricSocket = require '../asymmetric-socket'

describe 'BufferedSocket', ->
  describe '->connect', ->
    describe 'when constructed with resolveSrv and secure true', ->
      beforeEach ->
        @dns = resolveSrv: sinon.stub()
        @socket = new EventEmitter
        @socketIoClient = sinon.spy(=> @socket)

        options = resolveSrv: true, service: 'meshblu', domain: 'octoblu.com', secure: true
        dependencies = {@dns, @socketIoClient}

        @sut = new BufferedSocket options, dependencies

      describe 'when connect is called', ->
        beforeEach 'making the request', (done) ->
          @dns.resolveSrv.withArgs('_meshblu._socket-io-wss.octoblu.com').yields null, [{
            name: 'mesh.biz'
            port: 34
            priority: 1
            weight: 100
          }]
          @sut.connect done
          @socket.emit 'connect'

        it 'should call request with the resolved url', ->
          expect(@socketIoClient).to.have.been.calledWith 'wss://mesh.biz:34'

    describe 'when constructed with resolveSrv and secure false', ->
      beforeEach ->
        @dns = resolveSrv: sinon.stub()
        @socket = new EventEmitter
        @socketIoClient = sinon.spy(=> @socket)

        options = resolveSrv: true, service: 'meshblu', domain: 'octoblu.com', secure: false
        dependencies = {@dns, @socketIoClient}

        @sut = new BufferedSocket options, dependencies

      describe 'when connect is called', ->
        beforeEach 'making the request', (done) ->
          @dns.resolveSrv.withArgs('_meshblu._socket-io-ws.octoblu.com').yields null, [{
            name: 'insecure.xxx'
            port: 80
            priority: 1
            weight: 100
          }]
          @sut.connect done
          @socket.emit 'connect'

        it 'should call request with the resolved url', ->
          expect(@socketIoClient).to.have.been.calledWith 'ws://insecure.xxx:80'

    describe 'when constructed without resolveSrv', ->
      beforeEach ->
        @socket = new EventEmitter
        @socketIoClient = sinon.spy(=> @socket)

        options = resolveSrv: false, protocol: 'wss', hostname: 'thug.biz', port: 123
        dependencies = {@socketIoClient}

        @sut = new BufferedSocket options, dependencies

      describe 'when connect is called', ->
        beforeEach 'making the request', (done) ->
          @sut.connect done
          @socket.emit 'connect'

        it 'should call request with the formatted url', ->
          expect(@socketIoClient).to.have.been.calledWith 'wss://thug.biz:123'

    describe 'when constructed socketIO options', ->
      beforeEach ->
        @socket = new EventEmitter
        @socketIoClient = sinon.spy(=> @socket)

        options = {
          resolveSrv: false
          protocol: 'wss'
          hostname: 'thug.biz'
          port: 123
          socketIoOptions: {some_option: true}
        }
        dependencies = {@socketIoClient}

        @sut = new BufferedSocket options, dependencies

      describe 'when connect is called', ->
        beforeEach 'making the request', (done) ->
          @sut.connect done
          @socket.emit 'connect'

        it 'should call request with the formatted url', ->
          expect(@socketIoClient).to.have.been.calledWith 'wss://thug.biz:123', {
            some_option: true
            forceNew: true
          }

  describe 'with a connected BufferedSocket', ->
    @timeout 100

    beforeEach (done) ->
      @incoming = new EventEmitter
      @outgoing = new EventEmitter
      @socket = new AsymetricSocket {@incoming, @outgoing}
      @sut = new BufferedSocket {}, {socketIoClient: => @socket}
      @sut.connect done
      @incoming.emit 'connect'

    describe 'on "config"', ->
      beforeEach (done) ->
        @onConfig = sinon.spy => done()
        @sut.once 'config', @onConfig
        @incoming.emit 'config', foo: 'bar'

      it 'should proxy the event', ->
        expect(@onConfig).to.have.been.calledWith foo: 'bar'

    describe 'on "connect"', ->
      beforeEach (done) ->
        @onConnect = sinon.spy => done()
        @sut.once 'connect', @onConnect
        @incoming.emit 'connect', foo: 'bar'

      it 'should proxy the event', ->
        expect(@onConnect).to.have.been.calledWith foo: 'bar'

    describe 'on "disconnect"', ->
      beforeEach (done) ->
        @onDisconnect = sinon.spy => done()
        @sut.once 'disconnect', @onDisconnect
        @incoming.emit 'disconnect', 'Eula Tucker'

      it 'should proxy the event', ->
        expect(@onDisconnect).to.have.been.calledWith 'Eula Tucker'

    describe 'on "error"', ->
      beforeEach (done) ->
        @onError = sinon.spy => done()
        @sut.once 'error', @onError
        @incoming.emit 'error', 'Donald Bridges'

      it 'should proxy the event', ->
        expect(@onError).to.have.been.calledWith 'Donald Bridges'

    describe 'on "message"', ->
      beforeEach (done) ->
        @onMessage = sinon.spy => done()
        @sut.once 'message', @onMessage
        @incoming.emit 'message', name: 'me.net'

      it 'should proxy the event', ->
        expect(@onMessage).to.have.been.calledWith name: 'me.net'

    describe 'on "notReady"', ->
      beforeEach (done) ->
        @onNotReady = sinon.spy => done()
        @sut.once 'notReady', @onNotReady
        @incoming.emit 'notReady', lawba: 'Loretta Cannon'

      it 'should proxy the event', ->
        expect(@onNotReady).to.have.been.calledWith lawba: 'Loretta Cannon'

    describe 'on "ready"', ->
      beforeEach (done) ->
        @onReady = sinon.spy => done()
        @sut.once 'ready', @onReady
        @incoming.emit 'ready', mapjoziw: 'Edward Jensen'

      it 'should proxy the event', ->
        expect(@onReady).to.have.been.calledWith mapjoziw: 'Edward Jensen'
