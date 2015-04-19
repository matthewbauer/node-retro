RETRO = require('./constants')

module.exports = (gl, vertexShaderSource, fragmentShaderSource) ->
  _this = this

  this.pixelFormat = RETRO.PIXEL_FORMAT_0RGB1555

  webgl = require('./webgl')
  #webgl.resize gl

  program = webgl.createProgram gl,
    webgl.compileShader(gl, vertexShaderSource, gl.VERTEX_SHADER),
    webgl.compileShader(gl, fragmentShaderSource, gl.FRAGMENT_SHADER)

  gl.useProgram(program)
  positionLocation = gl.getAttribLocation(program, 'a_position')

  buffer = gl.createBuffer()
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer)
  gl.bufferData gl.ARRAY_BUFFER,
    new Float32Array([
      -1.0,  1.0,
       1.0,  1.0,
      -1.0, -1.0,
      -1.0, -1.0,
       1.0,  1.0,
       1.0, -1.0]), gl.STATIC_DRAW
  gl.enableVertexAttribArray(positionLocation)
  gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0)

  texCoordLocation = gl.getAttribLocation(program, 'a_texCoord')

  texCoordBuffer = gl.createBuffer()
  gl.bindBuffer(gl.ARRAY_BUFFER, texCoordBuffer)
  gl.bufferData gl.ARRAY_BUFFER,
    new Float32Array([
        0.0,  0.0,
        1.0,  0.0,
        0.0,  1.0,
        0.0,  1.0,
        1.0,  0.0,
        1.0,  1.0]), gl.STATIC_DRAW
  gl.enableVertexAttribArray(texCoordLocation)
  gl.vertexAttribPointer(texCoordLocation, 2, gl.FLOAT, false, 0, 0)

  texture = gl.createTexture()
  gl.bindTexture(gl.TEXTURE_2D, texture)

  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)

  @close = ->

  @refresh = (data, width, height, pitch) ->
    switch _this.pixelFormat
      when RETRO.PIXEL_FORMAT_0RGB1555
        bufferArray = new Uint16Array(data.length / 2)
        i = 0
        while i < data.length / 2
          bufferArray[i] = data.readUInt16BE(i * 2)
          i++
        gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0,
                      gl.RGBA, gl.UNSIGNED_SHORT_5_5_5_1, bufferArray
      when RETRO.PIXEL_FORMAT_XRGB8888
        gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0,
                      gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array(data)
      when RETRO.PIXEL_FORMAT_RGB565
        bufferArray = new Uint16Array(data.length / 2)
        i = 0
        while i < data.length / 2
          bufferArray[i] = data.readUInt16LE(i * 2)
          i++
        gl.texImage2D gl.TEXTURE_2D, 0, gl.RGB, width, height * 4, 0,
                      gl.RGB, gl.UNSIGNED_SHORT_5_6_5, bufferArray
    gl.drawArrays(gl.TRIANGLES, 0, 6)

  this
