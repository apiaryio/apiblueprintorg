# Packages
protagonist = require 'protagonist'
spawn = require('child_process').spawn
yaml = require 'js-yaml'

# Logging
log = require('./logging').get 'app/blueprint'


# Constants
PARSE_OPTIONS =
  requireBlueprintName: false
RUBY_TRACE_REGEXP = new RegExp /\/ruby*\.rb/


# Parses AST from given blueprint. Calls given callback with error
# and a "parse result", which contains warnings and AST.
parse = (blueprint, cb) ->
  protagonist.parse blueprint, PARSE_OPTIONS, (err, result) ->
    if err
      log.debug 'Cannot parse AST from blueprint', err
      result =
        warnings: []
    else
      log.debug 'Parsing code successful'
    cb err, result


# Composes blueprint from AST. Calls given callback with error
# and a string representing the original blueprint code.
compose = (ast, format, cb) ->
  # We have to check wellformness manually, because matter_compiler
  # doesn't handle it itself and fails badly. Can be removed after
  # https://github.com/apiaryio/matter_compiler/issues/5 is closed.
  try
    if format is 'yaml'
      yaml.safeLoad ast
    else
      JSON.parse ast
  catch err
    log.debug 'Cannot compose blueprint from AST, got invalid ' + format.toUpperCase(), err
    return cb err

  # using matter_compiler here as a subprocess
  matterCompiler = spawn 'matter_compiler', ['--format', format]

  stderr = ''
  stdout = ''

  matterCompiler.stdout.on 'data', (buff) ->
    stdout += buff.toString()
  matterCompiler.stderr.on 'data', (buff) ->
    data = buff.toString().trim()
    if data
      stderr += data

  matterCompiler.on 'close', (code) ->
    if code isnt 0 and not stderr
      stderr = 'Unknown error.'
    if stderr
      err = new Error stderr
      if RUBY_TRACE_REGEXP.test stderr
        throw err  # Ruby error!? -> our problem -> it should fail
      else
        log.debug 'Cannot compose blueprint from AST', err
        cb err
    else
      cb null, stdout

  matterCompiler.stdin.write ast
  matterCompiler.stdin.end()


# Export
module.exports = {
  parse
  compose
}
