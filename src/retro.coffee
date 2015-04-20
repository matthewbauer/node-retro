# node-retro JS wrapper

exports.RETRO = RETRO = require('./libretro_h')

exports.Video = require('./video')
exports.Input = require('./input')
exports.Audio = require('./audio')

exports.Core = (corefile, audio, input, video) ->
  _this = this

  @libretro = require('../build/Release/retro')

  @listeners = {}
  @overscan = true
  @variables = {}
  @variablesUpdate = false
  @interval = 20

  @setVariable = (key, value) ->
    _this.variables[key] = value
    _this.variablesUpdate = true

  @on = (event, cb) -> _this.listeners[event] = cb

  @emit = (event, args...) ->
    _this.listeners[event](args...) if _this.listeners[event]

  @on 'environment', (cmd, value) ->
    switch cmd
      when RETRO.ENVIRONMENT_SET_VARIABLES
        for key of value
          _this.variables[key] = value[key].split('; ')[1].split('|')[0]
        return true
      when RETRO.ENVIRONMENT_GET_OVERSCAN
        return _this.overscan
      when RETRO.ENVIRONMENT_GET_VARIABLE_UPDATE
        if _this.variablesUpdate
          _this.variablesUpdate = false
          return true
        return false
      when RETRO.ENVIRONMENT_SET_PIXEL_FORMAT
        video.pixelFormat = value
        return true
      when RETRO.ENVIRONMENT_GET_SYSTEM_DIRECTORY
        return '.'
      when RETRO.ENVIRONMENT_GET_VARIABLE
        return _this.variables[value]
      when RETRO.ENVIRONMENT_SET_INPUT_DESCRIPTORS
        return true
      else
        console.log('Unknown environment command ' + cmd)
        return false

  @on 'log', (level, fmt) -> console.log(fmt)
  @on 'videorefresh', video.refresh
  @on 'audiosamplebatch', audio.batch
  @on 'inputpoll', input.poll
  @on 'inputstate', input.state

  @loadGame = _this.libretro.loadGame
  @running = false

  @close = ->
    _this.listeners = {}
    _this.audio.close()
    _this.video.close()
    _this.input.close()
    _this.stop()
    _this.libretro.close()

  @start = ->
    _this.running = true
    _this.loop = setInterval(_this.libretro.run, _this.interval)

  @stop = ->
    clearInterval(_this.loop)
    _this.running = false

  @loadCore = (core) ->
    _this.libretro.listen(_this.emit)
    _this.libretro.loadCore(core)

  @loadCore(corefile) if corefile

  this
