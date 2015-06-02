os = require 'os'
fs = require 'fs'
url = require 'url'
path = require 'path'

request = require 'request'
unzip = require 'unzip'

{Core} = require './retro'

module.exports = (core) ->
  new Promise (resolve, reject) ->
    if process.platform is 'win32'
      corefile = "#{core}.dll"
    else if process.platform is 'darwin'
      corefile = "#{core}.dylib"
    else
      corefile = "#{core}.so"
    corepath = path.join os.tmpdir(), corefile
    if fs.existsSync corepath
      setImmediate ->
        resolve new Core corepath
    else
      platform = switch process.platform
        when 'win32'
          if process.arch is 'ia32'
            'win-x86'
          else
            'win-x86_64_w32'
        when 'darwin'
          if process.arch is 'ia32'
            'osx-x86'
          else
            'osx-x86_64'
        else 'linux/x86_64'
      request url.format
        protocol: 'http'
        hostname: 'buildbot.libretro.com'
        pathname: path.join 'nightly', platform, 'latest', "#{corefile}.zip"
      .pipe unzip.Parse()
      .on 'entry', (entry) ->
        if entry.type is 'File' and entry.path is corefile
          entry.pipe fs.createWriteStream corepath
          .on 'close', ->
            resolve new Core corepath
        else
          entry.autodrain()
      .on 'close', reject
