{EventEmitter} = require 'events'

class AsymetricSocket
  constructor: ->
    @incoming = new EventEmitter
    @outgoing = new EventEmitter

  connect: =>

  emit: =>
    @outgoing.emit arguments...

  off: =>
    @incoming.off arguments...

  once: =>
    @incoming.once arguments...

  on: =>
    @incoming.on arguments...

  send: =>
    @outgoing.emit arguments...

module.exports = AsymetricSocket
