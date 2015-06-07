should = require 'should'
nointro = require 'gametime-nointro'
{getCore} = require 'gametime-retro'
{Core} = require '../retro'

cores =
  snes9x_libretro:
    library_name: 'Snes9x'
    roms: [
      nointro_name: 'Super Mario World (USA)'
      nointro_console: 'Nintendo - Super Nintendo Entertainment System'
      file_name: 'Super Mario World (USA).sfc'
    ]

for corename, coreinfo of cores
  do (corename, coreinfo) ->
    describe "new Core('#{corename}')", ->
      core = null
      before (done) ->
        @timeout 20000
        getCore corename
        .then (path) ->
          core = new Core path
          done()
      it "register handlers...", ->
        core.on 'videorefresh', (data, width, height) ->
          data.should.be.a.ArrayBuffer
          width.should.be.a.Number
          height.should.be.a.Number
        core.on 'inputstate', (port, device, idx, id) ->
          port.should.be.a.Number
          device.should.be.a.Number
          idx.should.be.a.Number
          id.should.be.a.Number
        core.on 'audiosamplebatch', (left, right, frames) ->
          left.should.be.a.ArrayBuffer
          right.should.be.a.ArrayBuffer
          frames.should.be.a.Number
        core.on 'environment', (cmd, value) ->
          cmd.should.be.a.Number
      it "core should exist", ->
        core.should.exist
      it 'core.api_version() == 1', ->
        core.api_version().should.equal 1
      it 'core.getSystemInfo()', ->
        info = core.getSystemInfo()
        info.library_name.should.be.a.String
        info.library_name.should.equal coreinfo.library_name
        info.library_version.should.be.a.String
        info.valid_extensions.should.be.a.String
        info.need_fullpath.should.be.a.Boolean
        info.block_extract.should.be.a.Boolean
      it 'core.getSystemAVInfo()', ->
        info = core.getSystemAVInfo()
        info.should.have.property 'geometry'
        info.geometry.base_width.should.be.a.Number
        info.geometry.base_height.should.be.a.Number
        info.geometry.max_width.should.be.a.Number
        info.geometry.max_height.should.be.a.Number
        info.geometry.aspect_ratio.should.be.a.Number
        info.should.have.property 'timing'
        info.timing.fps.should.be.a.Number
        info.timing.sample_rate.should.be.a.Number
      it 'core.getRegion()', ->
        core.getRegion().should.be.within 0, 1
    for rom in coreinfo.roms
      do (rom) ->
        describe "loading #{rom.nointro_name}", ->
          it "running #{rom.nointro_name} for 50 frames", (done) ->
            getCore corename
            .then (path) ->
              core = new Core path
              nointro.getROM rom
              .then (buffer) ->
                core.loadGame buffer
                core.run() for a in [1..50]
                core.unloadGame()
                done()
          it "saving state...", (done) ->
            getCore corename
            .then (path) ->
              core = new Core path
              nointro.getROM rom
              .then (buffer) ->
                core.loadGame buffer
                core.run() for a in [1..5]
                save = core.serialize()
                save.should.exist
                save.should.be.a.Buffer
                done()
