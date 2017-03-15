{beforeEach, describe, it} = global
{expect} = require 'chai'
sinon = require 'sinon'

ProxySocket     = require '../../src/proxy-socket'
AsymetricSocket = require '../asymmetric-socket'

describe 'ProxySocket', ->
  @timeout 100

  describe 'with a connected BufferedSocket', ->
    beforeEach ->
      @socket = new AsymetricSocket
      @socket.connect = sinon.stub().yields null
      @sut = new ProxySocket {@socket}
      @sut._proxyDefaultIncomingEvents()

    describe 'on "config"', ->
      beforeEach (done) ->
        @onConfig = sinon.spy => done()
        @sut.once 'config', @onConfig
        @socket.incoming.emit 'config', foo: 'bar'

      it 'should proxy the event', ->
        expect(@onConfig).to.have.been.calledWith foo: 'bar'

    describe 'on "connect"', ->
      beforeEach (done) ->
        @onConnect = sinon.spy => done()
        @sut.once 'connect', @onConnect
        @socket.incoming.emit 'connect', foo: 'bar'

      it 'should proxy the event', ->
        expect(@onConnect).to.have.been.calledWith foo: 'bar'

    describe 'on "disconnect"', ->
      beforeEach (done) ->
        @onDisconnect = sinon.spy => done()
        @sut.once 'disconnect', @onDisconnect
        @socket.incoming.emit 'disconnect', 'Eula Tucker'

      it 'should proxy the event', ->
        expect(@onDisconnect).to.have.been.calledWith 'Eula Tucker'

    describe 'on "error"', ->
      beforeEach (done) ->
        @onError = sinon.spy => done()
        @sut.once 'error', @onError
        @socket.incoming.emit 'error', 'Donald Bridges'

      it 'should proxy the event', ->
        expect(@onError).to.have.been.calledWith 'Donald Bridges'

    describe 'on "message"', ->
      beforeEach (done) ->
        @onMessage = sinon.spy => done()
        @sut.once 'message', @onMessage
        @socket.incoming.emit 'message', name: 'me.net'

      it 'should proxy the event', ->
        expect(@onMessage).to.have.been.calledWith name: 'me.net'

    describe 'on "notReady"', ->
      describe 'when a generic "notReady" is emitted', ->
        beforeEach (done) ->
          @onNotReady = sinon.spy => done()
          @sut.once 'notReady', @onNotReady
          @socket.incoming.emit 'notReady', lawba: 'Loretta Cannon'

        it 'should proxy the event', ->
          expect(@onNotReady).to.have.been.calledWith lawba: 'Loretta Cannon'

    describe 'on "ratelimited"', ->
      beforeEach (done) ->
        @onReady = sinon.spy => done()
        @sut.once 'ratelimited', @onReady
        @socket.incoming.emit 'ratelimited', mapjoziw: 'Soozie Whoalzel'

      it 'should proxy the event', ->
        expect(@onReady).to.have.been.calledWith mapjoziw: 'Soozie Whoalzel'

    describe 'on "ready"', ->
      beforeEach (done) ->
        @onReady = sinon.spy => done()
        @sut.once 'ready', @onReady
        @socket.incoming.emit 'ready', mapjoziw: 'Edward Jensen'

      it 'should proxy the event', ->
        expect(@onReady).to.have.been.calledWith mapjoziw: 'Edward Jensen'
