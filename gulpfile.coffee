gulp  = require 'gulp'

coffeelint = require 'gulp-coffeelint'
mocha      = require 'gulp-mocha'
watch      = require 'gulp-watch'
yargs      = require 'yargs'


handleError = (err) ->
  console.error err.message
  process.exit 1

gulp.task 'test', ->
  gulp.src('tests/*-test.*', read:false)
    .pipe(mocha(reporter: 'spec'))
#    .pipe(mocha(reporter: 'spec', grep: yargs.argv.grep))
    .on 'error', handleError

# gulp.task 'integration-test', ->
#   gulp.src('tests/run-integration-tests.coffee')
#   .pipe(mocha(reporter: 'spec', grep: yargs.argv.grep))
#   .on 'error', handleError

gulp.task 'forgiving-test', ->
  gulp.src('tests/*-test.*')
    .pipe(mocha(reporter: 'dot', compilers: 'coffee:coffee-script'))
    .on 'error', (err) ->
      if err.name is 'SyntaxError'
        console.error 'You have a syntax error in file: ', err if err
      @emit 'end'

gulp.task 'lint', ->
  gulp.src(['./app/*', './tests/**/*'])
    .pipe(coffeelint(opt: {max_line_length: {value: 1024, level: 'ignore'}}))
    .pipe(coffeelint.reporter())
    .pipe(coffeelint.reporter('fail'))
    .on 'error', ->
      process.exit 1

gulp.task 'forgiving-lint', ->
  gulp.src(['./app/*', './tests/**/*'])
    .pipe(coffeelint(opt: {max_line_length: {value: 1024, level: 'ignore'}}))
    .pipe(coffeelint.reporter())
    .on 'error', ->
      @emit 'end'

  # gulp.src('./tests/*.coffee')
  #       .pipe(coffeelint(opt: max_line_length: 160))
  #       .pipe(coffeelint.reporter())


gulp.task 'citest', ['test'] #, 'integration-test']

gulp.task 'tdd', ->
  # gulp.watch 'src/*',  ['forgiving-lint', 'forgiving-test']
  # gulp.watch 'tests/*', ['forgiving-lint', 'forgiving-test']

  gulp.watch 'app/*',  ['forgiving-test']
  gulp.watch 'tests/*-test.*', ['forgiving-test']

gulp.task 'default', ['test']

return
