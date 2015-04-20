RETRO = require('./libretro_h')

# Boilerplate code taken from webglfundamentals.org
###*
# Creates and compiles a shader.
#
# @param {!WebGLRenderingContext} gl The WebGL Context.
# @param {string} shaderSource The GLSL source code for the shader.
# @param {number} shaderType The type of shader, VERTEX_SHADER or
#     FRAGMENT_SHADER.
# @return {!WebGLShader} The shader.
###
compileShader = (gl, shaderSource, shaderType) ->
  # Create the shader object
  shader = gl.createShader(shaderType)
  # Set the shader source code.
  gl.shaderSource(shader, shaderSource)
  # Compile the shader
  gl.compileShader(shader)
  # Check if it compiled
  success = gl.getShaderParameter(shader, gl.COMPILE_STATUS)
  shader

###*
# Creates a program from 2 shaders.
#
# @param {!WebGLRenderingContext) gl The WebGL context.
# @param {!WebGLShader} vertexShader A vertex shader.
# @param {!WebGLShader} fragmentShader A fragment shader.
# @return {!WebGLProgram} A program.
###
createProgram = (gl, vertexShader, fragmentShader) ->
  # create a program.
  program = gl.createProgram()
  # attach the shaders.
  gl.attachShader(program, vertexShader)
  gl.attachShader(program, fragmentShader)
  # link the program.
  gl.linkProgram program
  # Check if it linked.
  success = gl.getProgramParameter(program, gl.LINK_STATUS)
  program

resize = (gl) ->
  # Get the canvas from the WebGL context
  canvas = gl.canvas
  # Lookup the size the browser is displaying the canvas.
  displayWidth = canvas.clientWidth
  displayHeight = canvas.clientHeight
  # Check if the canvas is not the same size.
  if canvas.width != displayWidth or canvas.height != displayHeight
    # Make the canvas the same size
    canvas.width = displayWidth
    canvas.height = displayHeight
    # Set the viewport to match
    gl.viewport 0, 0, canvas.width, canvas.height

exports = (gl, vertexShaderSource, fragmentShaderSource) ->
  _this = this

  this.pixelFormat = RETRO.PIXEL_FORMAT_0RGB1555

  program = createProgram gl,
    compileShader(gl, vertexShaderSource, gl.VERTEX_SHADER),
    compileShader(gl, fragmentShaderSource, gl.FRAGMENT_SHADER)

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
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
  gl.pixelStorei(gl.UNPACK_ROW_LENGTH, 1)

  @close = ->

  @refresh = (data, width, height, pitch) ->
    switch _this.pixelFormat
      when RETRO.PIXEL_FORMAT_0RGB1555
        bufferArray = new Uint16Array(data.length / 2)
        line = 0
        while line < height
          x = 0
          while x < width
            bufferArray[line * width + x] = data.readUInt16BE(line*pitch+2*x)
            x++
          line++
        gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0,
                      gl.RGBA, gl.UNSIGNED_SHORT_5_5_5_1, bufferArray
      when RETRO.PIXEL_FORMAT_XRGB8888
        bufferArray = new Uint8Array(data.length)
        line = 0
        while line < height
          x = 0
          while x < width
            bufferArray[line * width + x] = data.readUInt8LE(line*pitch+x)
            x++
          line++
        gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0,
                      gl.RGBA, gl.UNSIGNED_BYTE, bufferArray
      when RETRO.PIXEL_FORMAT_RGB565
        bufferArray = new Uint16Array(data.length / 2)
        line = 0
        while line < height
          x = 0
          while x < width
            bufferArray[line * width + x] = data.readUInt16LE(line*pitch+2*x)
            x++
          line++
        gl.texImage2D gl.TEXTURE_2D, 0, gl.RGB, width, height, 0,
                      gl.RGB, gl.UNSIGNED_SHORT_5_6_5, bufferArray
    gl.drawArrays(gl.TRIANGLES, 0, 6)

  this
