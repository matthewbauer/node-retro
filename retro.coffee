# node-retro JS wrapper
module.exports = require './libretro_h'

os = require 'os'
fs = require 'fs'
path = require 'path'
url = require 'url'

binary = require 'node-pre-gyp'
path = require 'path'
{EventEmitter} = require 'events'

request = require 'request'
unzip = require 'unzip'

libretro_path = binary.find path.resolve path.join(__dirname, 'package.json')
module.exports.Core = class Core extends EventEmitter
  @listeners: {}
  constructor: (@core) ->
    libretro = require libretro_path
    @on 'newListener', (event, listener) ->
      @listeners[event] = listener
    libretro.listen (event, args...) =>
      @listeners[event](args) if event of @listeners
    libretro.loadCore @core
    {@loadGame, @loadGamePath, @run, @getSystemAVInfo,
    @getSystemInfo, @reset, @getRegion, @api_version,
    @serialize, @unserialize, @close} = libretro

module.exports.getCore = (core) ->
  new Promise (resolve, reject) ->
    if process.platform is 'win32'
      corefile = "#{core}.dll"
    else if process.platform is 'darwin'
      corefile = "#{core}.dylib"
    else
      corefile = "#{core}.so"
    corepath = path.join os.tmpdir(), corefile
    if fs.existsSync corepath
      resolve new Core corepath
    else
      platform = switch process.platform
        when 'win32'
          if process.arch is 'ia32'
            'win-x86'
          else
            'win-x86_64'
        when 'darwin'
          if process.arch is 'ia32'
            'osx-x86'
          else
            'osx-x86_64'
        else 'linux/x86_64'
      request "http://buildbot.libretro.com/nightly/#{platform}/latest/#{corefile}.zip"
      .pipe unzip.Parse()
      .on 'entry', (entry) ->
        if entry.type is 'File' and entry.path is corefile
          entry
          .pipe fs.createWriteStream corepath
          .on 'error', reject
          .on 'close', ->
            resolve new Core corepath
        else
          entry.autodrain()
      .on 'error', reject
      .on 'close', reject
