retro = require './retro.js'
should = require 'should'
describe 'loading a core', ->
  core = new retro.Core()
  it 'should be defined', ->
    should.exist core
