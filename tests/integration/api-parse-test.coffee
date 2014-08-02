require 'mocha'
{assert} = require 'chai'
request = require 'request'
yaml = require 'js-yaml'

require '../../app.coffee'


PORT = process.env.PORT
URL_PREFIX = "http://localhost:#{PORT}"


parse = (blueprint, accept, cb) ->
  request.post
    url: "#{URL_PREFIX}/parser"
    body: blueprint
    headers:
      'Accept': accept
  , cb


describe "Parsing", ->
  formats =
    whatever:
      accept: null
      contentType: 'application/vnd.apiblueprint.parseresult.raw+json'
      toParseResult: (body) -> JSON.parse body
    JSON:
      accept: 'application/vnd.apiblueprint.parseresult.raw+json'
      contentType: 'application/vnd.apiblueprint.parseresult.raw+json'
      toParseResult: (body) -> JSON.parse body
    YAML:
      accept: 'application/vnd.apiblueprint.parseresult.raw+yaml'
      contentType: 'application/vnd.apiblueprint.parseresult.raw+yaml'
      toParseResult: (body) -> yaml.safeLoad body

  defaultFormat = formats['whatever']

  bp = """
    # API
    Hello World!
  """
  result =
    _version: '1.0'
    ast:
      _version: '2.0'
      metadata: []
      name: 'API'
      description: 'Hello World!'
      resourceGroups: []
    warnings: []
    error: null

  for name, format of formats
    do (name, format) ->
      describe "When I POST a blueprint, accepting #{name}", ->
        res = undefined

        before (done) ->
          parse bp, format.accept, (err, r) ->
            assert.notOk err
            res = r
            done()
        it "I get HTTP 200", ->
          assert.equal 200, res.statusCode
        it "I get the right #{name} parse result", ->
          assert.deepEqual result, format.toParseResult res.body
        it "I get no error", ->
          assert.notOk format.toParseResult(res.body).error
        it "I get X-Parser-Time header", ->
          assert.ok res.headers['x-parser-time']
        it "I get _version in response", ->
          assert.ok format.toParseResult(res.body)._version
        it "I get the right #{name} parseresult Content-Type, without charset", ->
          assert.equal res.headers['content-type'], "#{format.contentType}; version=1.0"

  describe "When I POST no blueprint", ->
    res = undefined

    before (done) ->
      parse '', defaultFormat.accept, (err, r) ->
        assert.notOk err
        res = r
        done()
    it "I get HTTP 200", ->
      assert.equal 200, res.statusCode
    it "I get the right parse result", ->
      assert.deepEqual
        _version: '1.0'
        ast:
          _version: '2.0'
          metadata: []
          name: ''
          description: ''
          resourceGroups: []
        warnings: []
        error: null
      , defaultFormat.toParseResult res.body
    it "I get no error", ->
      assert.notOk defaultFormat.toParseResult(res.body).error

  describe "When I POST an invalid blueprint", ->
    res = undefined

    before (done) ->
      parse """
        # API
        + GET [/something]
        \t\tHello
      """, defaultFormat.accept, (err, r) ->
        assert.notOk err
        res = r
        done()
    it "I get HTTP 400", ->
      assert.equal 400, res.statusCode
    it "I get no AST", ->
      assert.notOk defaultFormat.toParseResult(res.body).ast
    it "I get an error", ->
      assert.ok defaultFormat.toParseResult(res.body).error
