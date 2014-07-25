require 'mocha'
{assert} = require 'chai'

blueprint = require '../lib/blueprint'


describe "Parsing", ->
  error = undefined

  describe "When I parse an invalid blueprint", ->
    it "I get no AST", -> assert false
    it "I get an error", -> assert false
    it "I get no warnings", -> assert false

  describe "When I parse suspicious, but valid blueprint", ->
    it "I get the right AST", -> assert false
    it "I get no error", -> assert false
    it "I get warnings", -> assert false

  describe "When I parse a valid blueprint", ->
    it "I get the right AST", -> assert false
    it "I get no error", -> assert false
    it "I get no warnings", -> assert false

  describe "When I parse blueprint without API name", ->
    bp = '''
      # GET /message
      + Response 200 (text/plain)

              Hello World!
    '''

    before (done) ->
      blueprint.parse bp, (err, result) ->
        error = err
        done null

    it "I get no error", -> assert.notOk error


describe "Composing", ->

  describe "When I compose an invalid JSON AST", ->
    it "I get no blueprint", -> assert false
    it "I get an error", -> assert false

  describe "When I compose an invalid YAML AST", ->
    it "I get the right blueprint", -> assert false
    it "I get no error", -> assert false

  describe "When I compose a valid JSON AST", ->
    it "I get no blueprint", -> assert false
    it "I get an error", -> assert false

  describe "When I compose a valid YAML AST", ->
    it "I get the right blueprint", -> assert false
    it "I get no error", -> assert false

  describe "When I cause matter_compiler to fail", ->
    it "I get no blueprint", -> assert false
    it "I get error of MatterCompilerError type", -> assert false
