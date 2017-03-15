{beforeEach, describe, it} = global
{expect} = require 'chai'
sinon = require 'sinon'

{EventEmitter}  = require 'events'
SrvSocket  = require '../../src/srv-socket'
AsymetricSocket = require '../asymmetric-socket'

describe 'SrvSocket spec', ->
  describe '->connect', ->
    describe 'when constructed with resolveSrv and secure true', ->
      beforeEach ->
        @dns = resolveSrv: sinon.stub()
        @socket = new AsymetricSocket
        @socketIoClient = sinon.spy(=> @socket)

        options = resolveSrv: true, service: 'meshblu', domain: 'octoblu.com', secure: true
        dependencies = {@dns, @socketIoClient}

        @sut = new SrvSocket options, dependencies

      describe 'when connect is called', ->
        beforeEach 'making the request', ->
          @dns.resolveSrv.withArgs('_meshblu._socket-io-wss.octoblu.com').yields null, [{
            name: 'mesh.biz'
            port: 34
            priority: 1
            weight: 100
          }]
          @sut.connect()
          @socket.incoming.emit 'connect'

        it 'should call request with the resolved url', ->
          expect(@socketIoClient).to.have.been.calledWith 'wss://mesh.biz:34'

    describe 'when constructed with resolveSrv and secure false', ->
      beforeEach ->
        @dns = resolveSrv: sinon.stub()
        @socket = new EventEmitter
        @socketIoClient = sinon.spy(=> @socket)

        options = resolveSrv: true, service: 'meshblu', domain: 'octoblu.com', secure: false
        dependencies = {@dns, @socketIoClient}

        @sut = new SrvSocket options, dependencies

      describe 'when connect is called', ->
        beforeEach 'making the request', ->
          @dns.resolveSrv.withArgs('_meshblu._socket-io-ws.octoblu.com').yields null, [{
            name: 'insecure.xxx'
            port: 80
            priority: 1
            weight: 100
          }]
          @sut.connect()
          @socket.emit 'connect'

        it 'should call request with the resolved url', ->
          expect(@socketIoClient).to.have.been.calledWith 'ws://insecure.xxx:80'

    describe 'when constructed without resolveSrv', ->
      beforeEach ->
        @socket = new EventEmitter
        @socketIoClient = sinon.spy(=> @socket)

        options = resolveSrv: false, protocol: 'wss', hostname: 'thug.biz', port: 123
        dependencies = {@socketIoClient}

        @sut = new SrvSocket options, dependencies

      describe 'when connect is called', ->
        beforeEach 'making the request', ->
          @sut.connect()
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

        @sut = new SrvSocket options, dependencies

      describe 'when connect is called', ->
        beforeEach 'making the request', ->
          @sut.connect()
          @socket.emit 'connect'

        it 'should call request with the formatted url', ->
          expect(@socketIoClient).to.have.been.calledWith 'wss://thug.biz:123', {
            some_option: true
            forceNew: true
            reconnection: false
          }

  describe 'with a connected socket', ->
    beforeEach ->
      @dns = resolveSrv: sinon.stub().yields null, [{
        name: 'secure.bikes'
        port: 443
        priority: 1
        weight: 100
      }]
      @socket = new AsymetricSocket
      @socket.close = sinon.spy()
      @socketIoClient = sinon.spy(=> @socket)

      options = resolveSrv: true, service: 'meshblu', domain: 'octoblu.com', secure: true
      dependencies = {@dns, @socketIoClient}

      @sut = new SrvSocket options, dependencies
      @sut.connect()
      @socket.incoming.emit 'connect'

    describe '->close', ->
      describe 'when called', ->
        beforeEach (done) ->
          @sut.close done
          @socket.incoming.emit 'disconnect'

        it 'should call close on the socket', ->
          expect(@socket.close).to.have.been.called

    describe '->send', ->
      describe 'when called', ->
        beforeEach (done) ->
          sinon.spy @socket, 'emit'
          @socket.outgoing.on 'message', => done()
          @sut.send 'message', 'Minerva Walters'

        it 'should call socket.emit', ->
          expect(@socket.emit).to.have.been.called
