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

exports.compileShader = (gl, shaderSource, shaderType) ->
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

exports.createProgram = (gl, vertexShader, fragmentShader) ->
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

exports.resize = (gl) ->
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
