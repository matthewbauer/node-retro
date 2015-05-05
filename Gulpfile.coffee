gulp = require('gulp')
coffee = require('gulp-coffee')
mocha = require('gulp-mocha')
shell = require('gulp-shell')

paths = {
  coffee: './src/*.coffee'
}

gulp.task('coffee', ->
  gulp.src(paths.coffee)
    .pipe(coffee())
    .pipe(gulp.dest('./lib/'))
)

gulp.task('mocha', ->
  gulp.src(['test/test*.coffee'], { read: false })
      .pipe(mocha({
        reporter: 'spec',
        globals: {
          should: require('should')
        }}))
  )

gulp.task('watch', ->
  gulp.watch(paths.coffee, ['coffee'])
)

gulp.task('gyp', shell.task([
  'node-pre-gyp install --fallback-to-build --target=0.12.1 --runtime=node-webkit'
]))

gulp.task('build', ['gyp', 'coffee'])
gulp.task('test', ['mocha'])
gulp.task('prebuild', ['coffee'])
gulp.task('prepublish', ['coffee'])

gulp.task('default', ['build', 'test'])
