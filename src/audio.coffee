RETRO = require('./libretro_h')

module.exports = (context) ->
  _this = this

  @batch = (buffer, frames) ->
    source = context.createBufferSource()

    audioBuffer = context.createBuffer(2, frames, context.sampleRate)

    leftBuffer = audioBuffer.getChannelData(0)
    rightBuffer = audioBuffer.getChannelData(1)
    i = 0
    while i < frames
      leftBuffer[i] = buffer.readFloatLE(i * 8)
      rightBuffer[i] = buffer.readFloatLE(i * 8 + 4)
      i++

    source.buffer = audioBuffer
    source.connect(context.destination)
    source.start(0)
    return frames

  @sample = (left, right) ->
    return # TODO: implement single frame sampling

  @close = ->
    context.close()

  this
