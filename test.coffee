retro = require './retro.js'
should = require 'should'

cores =
  snes9x_libretro:
    library_name: 'Snes9X'
    can_run: false
  dinothawr_libretro:
    library_name: 'Dinothawr'
    can_run: true
for name, info of cores
  describe "retro.getCore('#{name}')", ->
    core = null
    corename = name
    coreinfo = info
    before (done) ->
      retro.getCore(corename).then (c) ->
        core = c
        done()
    if coreinfo.can_run
      it 'core.run()', ->
        core.run()
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
      info.block_extract.should.be.a.Number
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
