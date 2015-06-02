# node-retro JS wrapper
module.exports = require './libretro_h'

path = require 'path'

binary = require 'node-pre-gyp'
{EventEmitter} = require 'events'

request = require 'request'

libretro_path = binary.find path.resolve path.join __dirname, 'package.json'
module.exports.Core = class Core extends EventEmitter
  listeners: {}
  buffer: {}
  constructor: (@file) ->
    libretro = require libretro_path
    @on 'newListener', (event, listener) ->
      if event of @buffer
        listener e... for e in @buffer[event]
        @buffer[event] = []
      @listeners[event] = listener
    libretro.listen (event, args...) =>
      return @listeners[event] args... if event of @listeners
      @buffer[event] ?= []
      @buffer[event].push args
    libretro.loadCore @file
    {@loadGame, @loadGamePath, @run, @getSystemAVInfo, @getSystemInfo, @reset,
    @getRegion, @api_version, @serialize, @unserialize, @start, @stop,
    @unloadGame} = libretro
