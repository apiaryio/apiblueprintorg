require 'mocha'
{assert} = require 'chai'
request = require 'request'

require '../../app.coffee'


PORT = process.env.PORT
URL_PREFIX = "http://localhost:#{PORT}"


describe "Options and CORS handling", ->
  [
    path: "/"
    methods: ['GET', 'HEAD']
  ,
    path: "/parser"
    methods: ['POST']
  ,
    path: "/composer"
    methods: ['POST']

  ].map (endpoint) ->
    res = undefined
    body = undefined
    url = "#{URL_PREFIX}#{endpoint.path}"
    allowed = endpoint.methods.join(', ') + ', OPTIONS'

    describe "Endpoint #{endpoint.path}", ->

      describe "When I send OPTIONS", ->
        before (done) ->
          request {method: 'OPTIONS', url}, (err, r, b) ->
            assert.notOk err
            res = r
            body = b
            done()
        it "I get HTTP 200", ->
          assert.equal 200, res.statusCode
        it "I get the right CORS headers", ->
          assert.equal 'true', res.headers['access-control-allow-credentials']
          assert.equal allowed, res.headers['access-control-allow-methods']
          assert.ok res.headers['access-control-allow-headers']
          assert.ok res.headers['access-control-allow-origin']
        it "I get empty response body", ->
          assert.equal '', body
        it "I get the right Allow header", ->
          assert.equal allowed, res.headers['allow']

      if 'GET' in endpoint.methods
        describe "When I can send GET", ->
          it "I have to be allowed to send also HEAD", ->
            assert res.headers['allow'].indexOf('HEAD') > -1

          describe "When I send HEAD", ->
            getRes = undefined
            headRes = undefined
            headBody = undefined

            before (done) ->
              request.get {url}, (err, r, b) ->
                assert.notOk err
                getRes = r
                request.head {url}, (err, r, b) ->
                  assert.notOk err
                  headRes = r
                  headBody = b
                  done()
            it "I get HTTP 200", ->
              assert.equal 200, headRes.statusCode
            it "I get the same headers as with GET", ->
              for header in ['content-length', 'etag']
                delete getRes.headers[header]
                delete headRes.headers[header]
              assert.deepEqual getRes.headers, headRes.headers
            it "I get empty response body", ->
              assert.equal '', headBody

      describe "When I send unsupported method", ->
        before (done) ->
          request.request {method: 'UNSUPPORTED', url}, (err, r, b) ->
            assert.notOk err
            res = r
            body = b
            done()
          it "I get HTTP 405", ->
            assert.equal 405, res.statusCode
          it "I get empty response body", ->
            assert.equal '', body
          it "I get the right Allow header", ->
            assert.equal allowed, res.headers['allow']
