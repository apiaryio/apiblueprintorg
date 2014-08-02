require 'mocha'
{assert} = require 'chai'
request = require 'request'
sinon = require 'sinon'
yaml = require 'js-yaml'

require '../../app.coffee'
{assertHeaderExists, assertHeaderEquals} = require './testutils.coffee'
blueprint = require '../../lib/blueprint.coffee'


PORT = process.env.PORT
URL_PREFIX = "http://localhost:#{PORT}"


compose = (serializedAst, contentType, cb) ->
  request.post
    url: "#{URL_PREFIX}/composer"
    body: serializedAst
    headers: if contentType then {'Content-Type': contentType} else {}
  , cb


describe "Composing", ->
  formats =
    'JSON without Content-Type':
      contentType: null
      serialize: (obj) -> JSON.stringify obj
    JSON:
      contentType: 'application/vnd.apiblueprint.ast.raw+json'
      serialize: (obj) -> JSON.stringify obj
    YAML:
      contentType: 'application/vnd.apiblueprint.ast.raw+yaml'
      serialize: (obj) -> yaml.safeDump obj

  defaultFormat = formats['JSON without Content-Type']

  bp = """
    # API
    Hello World!
  """
  ast =
    _version: '2.0'
    metadata: []
    name: 'API'
    description: 'Hello World!'
    resourceGroups: []

  for name, format of formats
    do (name, format) ->
      describe "When I POST an AST in #{name}", ->
        res = undefined

        before (done) ->
          compose format.serialize(ast), format.contentType, (err, r) ->
            assert.notOk err
            res = r
            done()
        it "I get HTTP 200", ->
          assert.equal 200, res.statusCode
        it "I get the right blueprint", ->
          assert.equal bp.trim(), res.body.trim()
        it "I get X-Composer-Time header", ->
          assertHeaderExists res, 'x-composer-time'
        it "I get the right Markdown Content-Type, with charset", ->
          assertHeaderEquals res, 'content-type', "text/vnd.apiblueprint+markdown; version=1A; charset=utf-8"

  describe "When I POST no AST", ->
    res = undefined

    before (done) ->
      compose '', defaultFormat.contentType, (err, r) ->
        assert.notOk err
        res = r
        done()
    it "I get HTTP 400", ->
      assert.equal 400, res.statusCode
    it "I get plain JSON Content-Type", ->
      assertHeaderEquals res, 'content-type', 'application/json'
    it "I get the error message", ->
      assert.ok JSON.parse(res.body).message

  describe "When I POST an invalid AST", ->
    res = undefined

    before (done) ->
      ast = defaultFormat.serialize
        _verzion: '2.0'
        metadata: []
        name: 'API'
        desc: 'Hello World!'
        reGroups: []
      compose ast, defaultFormat.contentType, (err, r) ->
        assert.notOk err
        res = r
        done()
    it "I get HTTP 400", ->
      assert.equal 400, res.statusCode
    it "I get plain JSON Content-Type", ->
      assertHeaderEquals res, 'content-type', 'application/json'
    it "I get the error message", ->
      assert.ok JSON.parse(res.body).message

  describe "When matter_compiler fails", ->
    res = undefined

    before (done) ->
      sinon.stub blueprint, 'compose', (ast, format, cb) ->
        cb new blueprint.MatterCompilerError 'Ouch!'
      compose defaultFormat.serialize(ast), defaultFormat.contentType, (err, r) ->
        assert.notOk err
        res = r
        done()
    after ->
      blueprint.compose.restore()
    it "I get HTTP 500", ->
      assert.equal 500, res.statusCode
    it "I get plain JSON Content-Type", ->
      assertHeaderEquals res, 'application/json'
