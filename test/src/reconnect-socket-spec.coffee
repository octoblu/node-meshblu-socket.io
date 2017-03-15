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
      @sut = new ReconnectSocket {backoffMin: 10, connectionTimeout: 10}, {SrvSocket: => @socket}

    describe '->close', ->
      beforeEach (done) ->
        @socket.close.yields()
        @sut.close done

      it 'should call close on the socket', ->
        expect(@socket.close).to.have.been.called

    describe '->connect', ->
      describe 'when connect yields right away', ->
        beforeEach ->
          @socket.connect = sinon.stub()
          @sut.connect()

        it 'should call socket.connect', ->
          expect(@socket.connect).to.have.been.called

    describe '->send', ->
      describe 'when called', ->
        beforeEach (done) ->
          sinon.spy @socket, 'send'
          @socket.outgoing.on 'message', => done()
          @sut.send 'message', 'Minerva Walters'

        it 'should call socket.send', ->
          expect(@socket.send).to.have.been.called
