# node-retro JS wrapper

module.exports = require('./libretro_h')

module.exports.Core = () ->
  @libretro = require('../build/Release/retro')

  @listeners = {}
  @on = (event, cb) => @listeners[event] = cb

  @emit = (event, args...) =>
    @listeners[event](args...) if event of @listeners

  @loadGame = @libretro.loadGame
  @run = @libretro.run

  @close = =>
    @listeners = {}
    @libretro.close()

  @loadCore = (corefile) =>
    @libretro.listen(@emit)
    @libretro.loadCore(corefile)

  @
