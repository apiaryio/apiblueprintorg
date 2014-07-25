require 'mocha'
{assert} = require 'chai'

{parse} = require '../lib/blueprint'


describe "Parsing", ->

  describe "When I send in the blueprint without API name", ->
    error = undefined

    before (done) ->
      parse 'xoxo', (err) ->
        error = err
        done null

    it 'I do not get an error', ->
      assert.notOk error
