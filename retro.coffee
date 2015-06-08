# node-retro JS wrapper
path = require 'path'

binary = require 'node-pre-gyp'
{EventEmitter} = require 'events'

libretro_path = binary.find path.resolve path.join __dirname, 'package.json'
libretro = require libretro_path
module.exports.Core = class Core extends EventEmitter
  listeners: {}
  buffer: {}
  constructor: (@file) ->
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
    @unloadGame, @unloadCore} = libretro
