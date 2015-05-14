require 'coffee-script/register'
gulp = require 'gulp'
coffee = require 'gulp-coffee'
mocha = require 'gulp-mocha'
shell = require 'gulp-shell'

gulp.task 'coffee', ->
  gulp.src(['retro.coffee', 'libretro_h.coffee'])
  .pipe(coffee())
  .pipe(gulp.dest '.')
gulp.task 'mocha', ['gyp', 'coffee'], ->
  gulp.src(['test.coffee'], read: false)
  .pipe mocha
    reporter: 'spec',
    globals:
      should: require 'should'
gulp.task 'gyp', shell.task [
  './node_modules/.bin/node-pre-gyp build'
]
gulp.task 'install', shell.task [
  './node_modules/.bin/node-pre-gyp install --fallback-to-build'
]

gulp.task 'build', ['gyp', 'coffee']
gulp.task 'test', ['mocha']
gulp.task 'prepublish', ['build']
gulp.task 'default', ['build', 'test']
