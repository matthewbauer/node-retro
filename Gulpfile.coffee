gulp = require('gulp')
coffee = require('gulp-coffee')

paths = {
  coffee: './src/*.coffee'
}

gulp.task('coffee', ->
  gulp.src(paths.coffee)
    .pipe(coffee())
    .pipe(gulp.dest('./lib/'))
)

gulp.task('build', ['coffee'])

gulp.task('watch', ->
  gulp.watch(paths.coffee, ['coffee'])
)

gulp.task('default', ['watch'])
