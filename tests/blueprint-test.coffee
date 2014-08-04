require 'mocha'
{assert} = require 'chai'
yaml = require 'js-yaml'

blueprint = require '../lib/blueprint'


describe "Parsing", ->
  describe "When I parse an invalid blueprint", ->
    bp = '''
      # API
      ## GET /message
      + Response 200. (text/plain)

      \t    Hello World!
    '''
    err = undefined
    result = undefined

    before (done) ->
      blueprint.parse bp, (e, r) ->
        err = e
        result = r
        done null
    it "I get no AST", ->
      assert.notOk result.ast
    it "I get an error", ->
      assert.ok err
    it "I get no warnings", ->
      assert.equal result.warnings?.length or 0, 0

  describe "When I parse suspicious, but valid blueprint", ->
    bp = '''
      # API
      ## GET /message

    '''
    err = undefined
    result = undefined

    before (done) ->
      blueprint.parse bp, (e, r) ->
        err = e
        result = r
        done null
    it "I get the right AST", ->
      assert.deepEqual result.ast,
        _version: '2.0'
        metadata: []
        name: 'API'
        description: ''
        resourceGroups: [
          name: ''
          description: ''
          resources: [
            name: ''
            description: ''
            uriTemplate: '/message'
            model: {}
            parameters: []
            actions: [
              name: ''
              description: ''
              method: 'GET'
              parameters: []
              examples: []
            ]
          ]
        ]
    it "I get no error", ->
      assert.notOk err
    it "I get warnings", ->
      assert result.warnings.length > 0

  describe "When I parse a valid blueprint", ->
    bp = '''
      # API
      ## GET /message
      + Response 200 (text/plain)

              Hello World!

    '''
    err = undefined
    result = undefined

    before (done) ->
      blueprint.parse bp, (e, r) ->
        err = e
        result = r
        done null
    it "I get the right AST", ->
      assert.deepEqual result.ast,
        _version: '2.0'
        metadata: []
        name: 'API'
        description: ''
        resourceGroups: [
          name: ''
          description: ''
          resources: [
            name: ''
            description: ''
            uriTemplate: '/message'
            model: {}
            parameters: []
            actions: [
              name: ''
              description: ''
              method: 'GET'
              parameters: []
              examples: [
                name: ''
                description: ''
                requests: []
                responses: [
                  name: "200"
                  description: ''
                  headers: [
                    name: 'Content-Type'
                    value: 'text/plain'
                  ]
                  body: 'Hello World!\n'
                  schema: ''
                ]
              ]
            ]
          ]
        ]
    it "I get no error", ->
      assert.notOk err
    it "I get no warnings", ->
      assert.equal result.warnings.length, 0

  describe "When I parse blueprint without API name", ->
    bp = '''
      # GET /message
      + Response 200 (text/plain)

              Hello World!
    '''
    err = undefined

    before (done) ->
      blueprint.parse bp, (e, r) ->
        err = e
        done null
    it "I get no error", ->
      assert.notOk err


describe "Composing", ->
  describe "When I compose an invalid JSON AST", ->
    ast = JSON.stringify
      _verzion: null
    err = undefined
    bp = undefined

    before (done) ->
      blueprint.compose ast, 'JSON', (e, b) ->
        err = e
        bp = b
        done null
    it "I get no blueprint", ->
      assert.notOk bp
    it "I get an error", ->
      assert.ok err

  describe "When I compose an invalid YAML AST", ->
    ast = yaml.safeDump
      _verzion: null
    err = undefined
    bp = undefined

    before (done) ->
      blueprint.compose ast, 'YAML', (e, b) ->
        err = e
        bp = b
        done null
    it "I get no blueprint", ->
      assert.notOk bp
    it "I get an error", ->
      assert.ok err

  describe "When I compose a valid JSON AST", ->
    ast = JSON.stringify
      _version: '2.0'
      metadata: []
      name: 'API'
      description: ''
      resourceGroups: [
        name: ''
        description: ''
        resources: [
          name: ''
          description: ''
          uriTemplate: '/message'
          model: {}
          parameters: []
          actions: [
            name: ''
            description: ''
            method: 'GET'
            parameters: []
            examples: []
          ]
        ]
      ]
    err = undefined
    bp = undefined

    before (done) ->
      blueprint.compose ast, 'JSON', (e, b) ->
        err = e
        bp = b
        done null
    it "I get the right blueprint", ->
      assert.equal bp, '''
        # API
        ## /message
        ### GET

      '''
    it "I get no error", ->
      assert.notOk err

  describe "When I compose a valid YAML AST", ->
    ast = yaml.safeDump
      _version: '2.0'
      metadata: []
      name: 'API'
      description: ''
      resourceGroups: [
        name: ''
        description: ''
        resources: [
          name: ''
          description: ''
          uriTemplate: '/message'
          model: {}
          parameters: []
          actions: [
            name: ''
            description: ''
            method: 'GET'
            parameters: []
            examples: []
          ]
        ]
      ]
    err = undefined
    bp = undefined

    before (done) ->
      blueprint.compose ast, 'YAML', (e, b) ->
        err = e
        bp = b
        done null
    it "I get the right blueprint", ->
      assert.equal bp, '''
        # API
        ## /message
        ### GET

      '''
    it "I get no error", ->
      assert.notOk err
