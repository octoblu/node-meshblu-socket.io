{beforeEach, describe, it} = global
{expect} = require 'chai'
sinon = require 'sinon'

_              = require 'lodash'

BufferedSocket  = require '../../src/buffered-socket'
AsymetricSocket = require '../asymmetric-socket'

describe 'BufferedSocket', ->
  @timeout 200

  describe '->constructor', ->
    describe 'when constructed with srvOptions', ->
      beforeEach ->
        @socket = new AsymetricSocket
        @socket.connect = sinon.stub()

        @ReconnectSocket = sinon.spy => @socket
        @sut = new BufferedSocket {srvOptions: {resolveSrv: true}}, {@ReconnectSocket}

      it 'should call the ReconnectSocket constructor with the srvOptions', ->
        expect(@ReconnectSocket).to.have.been.calledWithNew
        expect(@ReconnectSocket).to.have.been.calledWith {srvOptions: {resolveSrv: true}}

  describe 'with a BufferedSocket', ->
    beforeEach ->
      @socket = new AsymetricSocket
      @socket.close   = sinon.stub()
      @socket.connect = sinon.stub()

      @ReconnectSocket = sinon.spy => @socket
      @sut = new BufferedSocket {}, {@ReconnectSocket}

    describe '->close', ->
      describe 'when socket.close yields', ->
        beforeEach (done) ->
          @socket.close.yields null
          @sut.close done
          @socket.incoming.emit 'close'

        it 'should call socket.close', ->
          expect(@socket.close).to.have.been.called

    describe '->connect', ->
      describe 'when socket.connect yields', ->
        beforeEach ->
          @sut.connect()
          @socket.incoming.emit 'connect'

        it 'should call socket.connect', ->
          expect(@socket.connect).to.have.been.called

    describe '->send', ->
      describe 'when called once', ->
        beforeEach (done) ->
          @socket.outgoing.once 'message', => done()
          sinon.spy @socket, 'send'
          @sut.send 'message', foo: 'bar'

        it 'should call send on the socket', ->
          expect(@socket.send).to.have.been.calledWith 'message', foo: 'bar'

      describe 'when called twice', ->
        beforeEach (done) ->
          sinon.spy @socket, 'send'
          @sut.send 'message', foo: 'bar'
          @sut.send 'message', najal: 'Mario Schneider'
          _.delay done, 50

        it 'should call send on the socket once', ->
          expect(@socket.send).to.have.been.calledOnce
          expect(@socket.send).to.have.been.calledWith 'message', foo: 'bar'

        describe 'when 75 more milliseconds have elapsed (for a total of 125ms)', ->
          beforeEach (done) ->
            _.delay done, 75

          it 'should have called send on the socket twice', ->
            expect(@socket.send).to.have.been.calledTwice
            expect(@socket.send).to.have.been.calledWith 'message', najal: 'Mario Schneider'
