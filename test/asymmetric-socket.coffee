class AsymetricSocket
  constructor: ({@incoming, @outgoing}) ->

  emit: =>
    @outgoing.emit arguments...

  off: =>
    @incoming.off arguments...

  once: =>
    @incoming.once arguments...

  on: =>
    @incoming.on arguments...

module.exports = AsymetricSocket
