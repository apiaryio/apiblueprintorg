require 'mocha'
{assert} = require 'chai'
request = require 'request'

require '../../app.coffee'


PORT = process.env.PORT
URL_PREFIX = "http://localhost:#{PORT}"


parse = ({contentTypeCharset, acceptCharset}, cb) ->
  headers = {}
  if contentTypeCharset
    headers['Content-Type'] = "text/vnd.apiblueprint+markdown; version=1A; charset=#{contentTypeCharset}"
  if acceptCharset
    headers['Accept-Charset'] = "windows-1252, #{acceptCharset}; q=0.7,*;q=0.3"

  request.post
    url: "#{URL_PREFIX}/parser"
    body: """
      # API
      Hello World!
    """
    headers: headers
  , (err, res) ->
    cb err, res.statusCode, res.headers['content-type']


describe "Charset handling", ->
  statusCode = undefined
  contentType = undefined

  describe "When I POST a blueprint of unknown charset", ->
    before (done) ->
      parse {}, (err, code) ->
        assert.notOk err
        statusCode = code
        done()
    it "I get HTTP 200 (UTF-8 is assumed)", ->
      assert.equal 200, statusCode

  for utf8 in ['utf8', 'UTF8', 'utf-8', 'UTF-8']
    # see https://en.wikipedia.org/wiki/UTF-8#Official_name_and_variants
    describe "When I POST a blueprint declaring it's in #{utf8}", ->
      before (done) ->
        parse
          contentTypeCharset: utf8
        , (err, code) ->
          assert.notOk err
          statusCode = code
          done()
      it "I get HTTP 200", ->
        assert.equal 200, statusCode

  describe "When I POST a blueprint declaring it's in non-UTF-8", ->
    before (done) ->
      parse
        contentTypeCharset: 'iso-8859-1'
      , (err, code) ->
        assert.notOk err
        statusCode = code
        done()
    it "I get HTTP 415 (we reject data in non-UTF-8)", ->
      assert.equal 415, statusCode

  describe "When I POST a blueprint, preferring the response to be in non-UTF-8 charset", ->
    before (done) ->
      parse
        acceptCharset: 'iso-8859-1'
      , (err, code, type) ->
        assert.notOk err
        statusCode = code
        contentType = type.toLowerCase()
        done()
    it "I get HTTP 200 (Accept-Charset is just a preference)", ->
      assert.equal 200, statusCode
