gulp           = require 'gulp'
clean          = require 'gulp-clean'
coffee         = require 'gulp-coffee'

gulp.task 'build', ->
  gulp.src ['./src/**/*.coffee']
    .pipe coffee()
    .pipe gulp.dest('./dist/')

gulp.task 'clean', ->
  gulp.src './dist/', read: false
    .pipe clean()

gulp.task 'default', ['build']
