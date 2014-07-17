require 'mocha'
{assert}     = require 'chai'


{getLocalAst} = require '../app/blueprint'

describe "getLocalAst", ->

  describe "When I send in the blueprint without API name", ->
    error = undefined

    before (done) ->
      getLocalAst 'xoxo', (err) ->
        error = err
        done null

    it 'I got an error', ->
      assert.ok error
