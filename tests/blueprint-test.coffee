require 'mocha'
{assert} = require 'chai'

{parse} = require '../lib/blueprint'


describe "parse", ->

  describe "When I send in the blueprint without API name", ->
    error = undefined

    before (done) ->
      parse 'xoxo', (err) ->
        error = err
        done null

    it 'I do not got an error', ->
      assert.notOk error
