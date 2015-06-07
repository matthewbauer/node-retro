require 'coffee-script/register'
gulp = require 'gulp'
coffee = require 'gulp-coffee'
mocha = require 'gulp-mocha'
shell = require 'gulp-shell'

gulp.task 'coffee', ->
  gulp.src ['retro.coffee', 'libretro_h.coffee']
  .pipe coffee()
  .pipe gulp.dest '.'
require 'coffee-coverage/register-istanbul'
gulp.task 'mocha', ['gyp', 'coffee'], ->
  gulp.src 'spec/*.coffee'
  .pipe mocha()
gulp.task 'gyp', shell.task [
  'node-pre-gyp configure build'
]
gulp.task 'install', shell.task [
  'node-pre-gyp install --fallback-to-build'
]
gulp.task 'publish', shell.task [
  'node-pre-gyp package unpublish publish'
]
gulp.task 'build', ['gyp', 'coffee']
gulp.task 'travis', ['build', 'test', 'publish']
gulp.task 'test', ['mocha']
gulp.task 'prepublish', ['build']
gulp.task 'default', ['build', 'test']
