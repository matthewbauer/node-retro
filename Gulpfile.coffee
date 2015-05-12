require 'coffee-script/register'
gulp = require 'gulp'
coffee = require 'gulp-coffee'
mocha = require 'gulp-mocha'
shell = require 'gulp-shell'

gulp.task 'coffee', ->
  gulp.src(['retro.coffee', 'libretro_h.coffee'])
  .pipe(coffee())
  .pipe(gulp.dest '.')
gulp.task 'mocha', ->
  gulp.src(['test.coffee'], read: false).pipe mocha
    reporter: 'spec',
    globals:
      should: require 'should'

gulp.task 'gyp', shell.task [
  './node_modules/node-pre-gyp/bin/node-pre-gyp configure build'
]
gulp.task 'build', ['gyp', 'coffee']
gulp.task 'test', ['mocha']
gulp.task 'prebuild', ['coffee']
gulp.task 'prepublish', ['coffee']
gulp.task 'binding', ['gyp']
gulp.task 'default', ['build', 'test']
