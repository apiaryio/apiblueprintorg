require 'mocha'
{assert} = require 'chai'
request = require 'request'

require '../../app.coffee'


PORT = process.env.PORT
URL_PREFIX = "http://localhost:#{PORT}"


describe "Root endpoint", ->
  url = "#{URL_PREFIX}/"
  res = undefined
  body = undefined

  describe "When I send GET", ->
    before (done) ->
      request.get {url, json: true}, (err, r, b) ->
        assert.notOk err
        res = r
        body = b
        done()
    it "I get HTTP 200", ->
      assert.equal 200, res.statusCode
    it "I get the right response body", ->
      assert.deepEqual body,
        _links:
          self: { href: '/' }
          parse: { href: '/parser' }
          compose: { href: '/composer' }
    it "I get HAL Content-Type", ->
      assert.equal 'application/hal+json', res.headers['content-type']
    it "I get the Link header", ->
      assert.ok res.headers['link']
