require 'mocha'
{assert} = require 'chai'
request = require 'request'
sinon = require 'sinon'
express = require 'express'
path = require 'path'
winston = require 'winston'

require '../../app.coffee'
blueprint = require '../../lib/blueprint.coffee'
log = require('../../lib/logging').get 'app/blueprint'


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


  describe "When causing a matter_compiler error", ->
    sysPath = process.env.PATH.split path.delimiter
    logging = []
    ast =
      _version: '2.0'
      metadata: []
      name: 'API'
      description: 'Hello World!'
      resourceGroups: []

    before (done) ->
      # capture logging
      log.on 'logging', (transport, level, msg, meta) ->
        logging.push
          level: level
          firstLine: msg
          message: meta.message
          name: meta.name
          ast: meta.ast

      # prepending system PATH with ./bin, where is fake matter_compiler, which
      # always fails and throws terrible errors
      sysPath.unshift path.join __dirname, 'bin'
      process.env.PATH = sysPath.join path.delimiter

      request.post
        url: "#{URL_PREFIX}/composer"
        body: JSON.stringify ast
      , (err, r) ->
        assert.notOk err
        res = r
        done()

    after ->
      # return system PATH to its original value
      sysPath.shift()
      process.env.PATH = sysPath.join path.delimiter

    it "I get HTTP 500", ->
      assert.equal 500, res.statusCode

    it "I get plain JSON Content-Type", ->
      assert.equal 'application/json', res.headers['content-type']

    it "I get JSON in the error format", ->
      assert.ok JSON.parse(res.body).message

    describe "and MatterCompilerError", ->
      error = undefined

      before ->
        error = (entry for entry in logging when entry.name is 'MatterCompilerError')[0]

      it "is present in log", ->
        assert.ok error

      it "has a short message", ->
        assert.ok error.firstLine

      it "has full stderr output from matter_compiler", ->
        assert error.firstLine.length <= error.message.length, 'is shorter than or equal to'

      it "has full AST, which caused the problem", ->
        assert.deepEqual ast, JSON.parse error.ast
