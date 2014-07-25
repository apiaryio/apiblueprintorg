require 'mocha'
Test = require('mocha').Test
http = require 'http'
htmlparser = require 'htmlparser2'
{assert} = require 'chai'

{parse} = require '../../lib/blueprint'


download = (cb) ->
  html = ''
  err = undefined
  req = http.request
    host: 'apiblueprint.org'
    port: 80
    path: ''
    method: 'GET'
  , (res) ->
    res.setEncoding 'utf8'
    res.on 'data', (chunk) -> html += chunk
    res.on 'error', (e) -> err = e
    res.on 'end', -> cb err, html
  req.end()

parseExamples = (html, cb) ->
  err = undefined
  blueprints = []
  asts = []

  writeBlueprint = false
  writeAst = false

  parser = new htmlparser.Parser
    onopentag: (name, attrs) ->
      if name == 'code'
        writeBlueprint = (attrs.class == 'markdown')
        writeAst = (attrs.class == 'ast')
    ontext: (text) ->
      if writeBlueprint
        blueprints.push text
      else if writeAst
        asts.push JSON.parse text
    onclosetag: (name) ->
      writeBlueprint = false
      writeAst = false
    onerror: (e) ->
      err = e
    onend: ->
      cb err, ({blueprint, ast: asts[i]} for blueprint, i in blueprints)

  parser.write html
  parser.end()


suite = describe "apiblueprint.org", ->
  examples = undefined

  before (done) ->
    download (err, html) ->
      if err then return done err
      parseExamples html, (err, result) ->
        examples = result
        if err then return done err

        # We add tests dynamically here, because we can't use `examples` variable
        # out of `describe`s and `it`s to iterate over it - it's not filled yet.
        # Also, `describe`s are not async and we can't have nested `it`s.
        for example, i in examples
          ast = undefined

          suite.addTest new Test "Example ##{i + 1} has parseable blueprint", (done) ->
            parse example.blueprint, (err, result) ->
              assert.notOk err
              ast = result.ast
              done()

          suite.addTest new Test "Example ##{i + 1} has the right AST", ->
            assert.deepEqual ast, example.ast

        done()

  it "has examples", ->
    assert examples.length > 0
    # this one just makes sure dynamic tests added above will be executed
