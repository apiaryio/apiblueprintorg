require 'mocha'
{assert} = require 'chai'
request = require 'request'
sinon = require 'sinon'
yaml = require 'js-yaml'

require '../../app.coffee'
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
  res = undefined

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

  defaultFormat = (format for name, format of formats)[0]

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
          assert.ok res.headers['x-composer-time']
        it "I get the right Markdown Content-Type, with charset", ->
          assert.equal res.headers['content-type'], "text/vnd.apiblueprint+markdown; version=1A; charset=utf-8"

  describe "When I POST no AST", ->
    before (done) ->
      compose '', defaultFormat.contentType, (err, r) ->
        assert.notOk err
        res = r
        done()
    it "I get HTTP 400", ->
      assert.equal 400, res.statusCode
    it "I get plain JSON Content-Type", ->
      assert.equal 'application/json', res.headers['content-type']
    it "I get the error message", ->
      assert.ok JSON.parse(res.body).message

  describe "When I POST an invalid AST", ->
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
      assert.equal 'application/json', res.headers['content-type']
    it "I get the error message", ->
      assert.ok JSON.parse(res.body).message

  describe "When matter_compiler fails", ->
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
      assert.equal 'application/json', res.headers['content-type']