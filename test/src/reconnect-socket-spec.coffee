{beforeEach, describe, it} = global
{expect} = require 'chai'
sinon    = require 'sinon'

_           = require 'lodash'

ReconnectSocket  = require '../../src/reconnect-socket'
AsymmetricSocket = require '../asymmetric-socket'

describe 'ReconnectSocket', ->
  describe '->constructor', ->
    describe 'when srvOptions are passed in', ->
      beforeEach ->
        @socket = new AsymmetricSocket
        @socket.connect = sinon.stub()

        srvOptions = {port: 123, hostname: 'foo.biz'}
        @SrvSocket = sinon.spy(=> @socket)

        new ReconnectSocket {srvOptions}, {@SrvSocket}

      it 'should pass them to the SrvSocket constructor', ->
        expect(@SrvSocket).to.have.been.calledWithNew
        expect(@SrvSocket).to.have.been.calledWith {port: 123, hostname: 'foo.biz'}

  describe 'when constructed', ->
    beforeEach ->
      @socket = new AsymmetricSocket
      @socket.close   = sinon.stub()
      @socket.connect = sinon.stub()
      @sut = new ReconnectSocket {backoffMin: 10, connectionTimeout: 10}, {SrvSocket: => @socket}

    describe '->close', ->
      beforeEach (done) ->
        @socket.close.yields()
        @sut.close done

      it 'should call close on the socket', ->
        expect(@socket.close).to.have.been.called

    describe '->connect', ->
      describe 'when connect yields right away', ->
        beforeEach (done) ->
          @socket.connect.yields()
          @sut.connect done

        it 'should call socket.connect', ->
          expect(@socket.connect).to.have.been.called

      describe 'when socket.connect takes too long to yield (never yields)', ->
        beforeEach (done) ->
          @onNotReady = sinon.spy()
          @sut.on 'notReady', @onNotReady
          @sut.connect (@error) => done()

        it 'should yield an error', ->
          expect(=> throw @error).to.throw 'Connection Timeout'

        it 'should emit "notReady"', ->
          expect(@onNotReady).to.have.been.calledWith {status: 504, message: 'Connection Timeout'}

    describe '->send', ->
      describe 'when called', ->
        beforeEach (done) ->
          sinon.spy @socket, 'send'
          @socket.outgoing.on 'message', => done()
          @sut.send 'message', 'Minerva Walters'

        it 'should call socket.send', ->
          expect(@socket.send).to.have.been.called

    describe 'on "notReady"', ->
      describe 'when a rate-limiting "notReady" is emitted with no error', ->
        beforeEach (done) ->
          @sut.once 'notReady', => done()
          @socket.incoming.emit 'notReady', lawba: 'Loretta Cannon'

        it 'should not try to reconnect', ->
          expect(@socket.connect).not.to.have.been.called

      describe 'when a rate-limiting "notReady" is emitted with 429 error code (and we wait 75ms)', ->
        beforeEach (done) ->
          @socket.incoming.emit 'notReady', error: {code: 429}
          _.delay done, 75

        it 'should attempt to reconnect the socket', ->
          expect(@socket.connect).to.have.been.called

        describe 'when a second rate-limiting "notReady" is emitted with 429 error code', ->
          beforeEach ->
            @socket.connect.reset()
            @socket.incoming.emit 'notReady', error: {code: 429}

          it 'should not attempt to reconnect the socket', ->
            expect(@socket.connect).not.to.have.been.called

          describe 'when we wait 90ms', ->
            beforeEach (done) ->
              @timeout 110
              _.delay done, 100

            it 'should attempt to reconnect the socket', ->
              expect(@socket.connect).to.have.been.called

        describe 'when a 30 more rate-limiting "notReady" are emitted with 429 error code', ->
          beforeEach ->
            @socket.connect.reset()
            _.times 30, => @socket.incoming.emit 'notReady', error: {code: 429}

          it 'should not attempt to reconnect the socket', ->
            expect(@socket.connect).not.to.have.been.called

          it 'should set the timeout way into the future', ->
            expect(@sut._reconnectTimeout._idleTimeout).to.be.greaterThan 1000000
