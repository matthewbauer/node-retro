RETRO = require('./libretro_h')

module.exports = (keyBindings) ->
  _this = this

  _this.keyboard = _this.joypad = _this.mouse = {}
  _this.lightgun = _this.analog = _this.pointer = {}

  @eventHandler = (event) ->
    switch event.type
      when 'keydown'
        _this.keyboard[event.which] = true
        if keyBindings[event.which]
          _this.joypad[keyBindings[event.which]] = true
        event.preventDefault()
      when 'keyup'
        _this.keyboard[event.which] = false
        if keyBindings[event.which]
          _this.joypad[keyBindings[event.which]] = false
        event.preventDefault()

  @state = (port, device, idx, id) ->
    switch device
      when RETRO.DEVICE_JOYPAD
        return _this.joypad[id]
      when RETRO.DEVICE_MOUSE
        return _this.mouse[id]
      when RETRO.DEVICE_KEYBOARD
        return _this.keyboard[id]
      when RETRO.DEVICE_LIGHTGUN
        return _this.lightgun[id]
      when RETRO.DEVICE_ANALOG
        return _this.analog[id]
      when RETRO.DEVICE_POINTER
        return _this.pointer[id]

  @poll = ->
    return # polling is handled by webkit

  @close = ->

  this
