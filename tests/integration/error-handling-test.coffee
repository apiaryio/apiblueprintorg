require 'mocha'
{assert} = require 'chai'
request = require 'request'
sinon = require 'sinon'
express = require 'express'

api = require '../../lib/controllers/api.coffee'
blueprint = require '../../lib/blueprint.coffee'


PORT = process.env.PORT
URL_PREFIX = "http://localhost:#{PORT}"


describe "Handling errors", ->
  env = undefined
  res = undefined

  before ->
    env = process.env.NODE_ENV
    process.env.NODE_ENV = 'production'
  after ->
    process.env.NODE_ENV = env

  describe "When requesting a non-existing path", ->
    before (done) ->
      request.put
        url: "#{URL_PREFIX}/zetor-tractor-is-going-to-the-mountains-to-plow-potatoes"
        body: """
          # API
          Hello World!
        """
      , (err, r) ->
        assert.notOk err
        res = r
        done()
    it "I get HTTP 404", ->
      assert.equal 404, res.statusCode
    it "I get plain JSON Content-Type", ->
      assert.equal 'application/json', res.headers['content-type']

  describe "When causing an internal server error", ->
    msg = 'Ouch!'

    before (done) ->
      sinon.stub blueprint, 'parse', (bp, cb) ->
        throw new Error msg
      request.post
        url: "#{URL_PREFIX}/parser"
        body: """
          # API
          Hello World!
        """
      , (err, r) ->
        assert.notOk err
        res = r
        done()
    after ->
      blueprint.parse.restore()
    it "I get HTTP 500", ->
      assert.equal 500, res.statusCode
    it "I get plain JSON Content-Type", ->
      assert.equal 'application/json', res.headers['content-type']
    it "I get the error message in description", ->
      assert.equal msg, JSON.parse(res.body).description
