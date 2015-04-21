gulp = require('gulp')
coffee = require('gulp-coffee')
mocha = require('gulp-mocha')

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

gulp.task('build', ['coffee'])
gulp.task('test', ['mocha'])
gulp.task('prebuild', ['coffee'])
gulp.task('prepublish', ['coffee'])

gulp.task('default', ['watch'])
