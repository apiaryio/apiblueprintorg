gulp = require 'gulp'
coffeelint = require 'gulp-coffeelint'
mocha = require 'gulp-mocha'
watch = require 'gulp-watch'
yargs = require 'yargs'


handleError = (err) ->
  console.error err.message
  process.exit 1


gulp.task 'test', ->
  gulp.src('tests/*-test.*', read: false)
    .pipe(mocha(reporter: 'spec', grep: yargs.argv.grep))
    .on 'error', handleError


gulp.task 'forgiving-test', ->
  gulp.src('tests/*-test.*')
    .pipe(mocha(reporter: 'dot', compilers: 'coffee:coffee-script'))
    .on 'error', (err) ->
      if err.name is 'SyntaxError'
        console.error 'You have a syntax error in file: ', err if err
      @emit 'end'


# gulp.task 'integration-test', ->
#   gulp.src('tests/run-integration-tests.coffee')
#   .pipe(mocha(reporter: 'spec', grep: yargs.argv.grep))
#   .on 'error', handleError


gulp.task 'lint', ->
  gulp.src(['./*.coffee', './lib/*', './tests/**/*'])
    .pipe(coffeelint(opt: {max_line_length: {value: 1024, level: 'ignore'}}))
    .pipe(coffeelint.reporter())
    .pipe(coffeelint.reporter('fail'))
    .on 'error', ->
      process.exit 1


gulp.task 'forgiving-lint', ->
  gulp.src(['./*.coffee', './lib/*', './tests/**/*'])
    .pipe(coffeelint(opt: {max_line_length: {value: 1024, level: 'ignore'}}))
    .pipe(coffeelint.reporter())
    .on 'error', ->
      @emit 'end'


gulp.task 'citest', ['test'] #, 'integration-test']


gulp.task 'tdd', ->
  gulp.watch 'lib/*',  ['forgiving-lint', 'forgiving-test']
  gulp.watch 'tests/*-test.*', ['forgiving-lint', 'forgiving-test']


gulp.task 'default', ['test']


return
