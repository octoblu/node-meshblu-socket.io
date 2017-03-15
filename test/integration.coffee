MeshbluSocketIo = require '../index'
MeshbluConfig = require 'meshblu-config'
async = require 'async'

options = new MeshbluConfig
options.bufferRate = 5

connect = ->
  meshblu = new MeshbluSocketIo options

  console.log 'wow'

  meshblu.on 'error', (error) ->
    console.error 'error:', error

  meshblu.on 'disconnect', (error) ->
    console.error 'disconnect:', error

  meshblu.on 'notReady', (error) ->
    console.error 'notReady:', error

  meshblu.on 'connect_error', (error) ->
    console.error 'connect_error:', error

  meshblu.on 'identify', (error) ->
    console.error 'identify:', error

  meshblu.on 'ratelimited', (error) ->
    console.error 'ratelimited', error

  message = (n, callback) ->
    meshblu.message {'devices':['14d14750-b5d9-4760-a2dc-7b9f90f28ac5'], 'hello':'world', n}, (error) ->
      callback error, n

  meshblu.on 'ready', ->
    console.log 'ready'
    async.times 3000, message, (error, data) ->
      console.log JSON.stringify({error},null,2)

  meshblu.connect()

connect()
