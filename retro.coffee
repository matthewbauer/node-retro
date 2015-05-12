# node-retro JS wrapper
module.exports = require './libretro_h'
binary = require 'node-pre-gyp'
path = require 'path'

libretro_path = binary.find path.resolve(path.join(__dirname, 'package.json'))

module.exports.Core = ->
  @libretro = require libretro_path
  @listeners = {}

  @on = (event, cb) -> @listeners[event] = cb
  @emit = (event, args...) -> @listeners[event] args...

  @loadGame = @libretro.loadGame
  @loadGamePath = @libretro.loadGamePath
  @run = @libretro.run
  @play = @libretro.play
  @stop = @libretro.stop
  @getSystemAVInfo = @libretro.getSystemAVInfo
  @getSystemInfo = @libretro.getSystemInfo
  @reset = @libretro.reset
  @getRegion = @libretro.getRegion
  @api_version = @libretro.api_version
  @getMemoryData = @libretro.getMemoryData
  @setMemoryData = @libretro.setMemoryData
  @serialize = @libretro.serialize
  @unserialize = @libretro.unserialize

  @close = ->
    @listeners = {}
    @libretro.close()

  @loadCore = (corefile) ->
    @libretro.listen @emit
    @libretro.loadCore corefile

  @
