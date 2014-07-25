require 'mocha'
{assert} = require 'chai'


describe "Root endpoint", ->

  describe "When I send OPTIONS", ->
    it "I get HTTP 204", -> assert false
    it "I get CORS headers", -> assert false
    it "I get empty response body", -> assert false
    it "I get the right Accept header", -> assert false

  describe "When I send HEAD", ->
    it "I get HTTP 204", -> assert false
    it "I get empty response body", -> assert false

  describe "When I send GET", ->
    it "I get HTTP 200", -> assert false
    it "I get the right response body", -> assert false
    it "I get HAL Content-Type", -> assert false
    it "I get the right Link header", -> assert false


describe "Handling errors", ->

  describe "When requesting a non-existing path", ->
    it "I get HTTP 404", -> assert false
    it "I get plain JSON Content-Type", -> assert false

  describe "When causing an internal server error", ->
    it "I get HTTP 500", -> assert false
    it "I get plain JSON Content-Type", -> assert false


describe "Parsing", ->

  describe "When I send OPTIONS", ->
    it "I get HTTP 204", -> assert false
    it "I get CORS headers", -> assert false
    it "I get empty response body", -> assert false
    it "I get the right Accept header", -> assert false

  describe "When I send HEAD", ->
    it "I get HTTP 405", -> assert false
    it "I get empty response body", -> assert false
    it "I get the right Accept header", -> assert false

  describe "When I send GET", ->
    it "I get HTTP 405", -> assert false
    it "I get empty response body", -> assert false
    it "I get the right Accept header", -> assert false

  describe "When I POST a blueprint, accepting whatever", ->
    it "I get HTTP 200", -> assert false
    it "I get CORS headers", -> assert false
    it "I get JSON AST", -> assert false
    it "I get no error", -> assert false
    it "I get X-Parser-Time header", -> assert false
    it "I get _version in response", -> assert false
    it "I get the right JSON parseresult Content-Type, without charset", -> assert false

  describe "When I POST a blueprint declaring it's in UTF-8, accepting whatever", ->
    it "I get HTTP 200", -> assert false

  describe "When I POST a blueprint declaring it's in non-UTF-8, accepting whatever", ->
    it "I get HTTP 415", -> assert false

  describe "When I POST a blueprint, accepting UTF-8 charset", ->
    it "I get HTTP 200", -> assert false

  describe "When I POST a blueprint, accepting non-UTF-8 charset", ->
    it "I get HTTP 406", -> assert false

  describe "When I POST a blueprint, accepting JSON", ->
    it "I get HTTP 200", -> assert false
    it "I get JSON AST", -> assert false
    it "I get the right JSON parseresult Content-Type, without charset", -> assert false

  describe "When I POST a blueprint, accepting YAML", ->
    it "I get HTTP 200", -> assert false
    it "I get YAML AST", -> assert false
    it "I get the right YAML parseresult Content-Type, without charset", -> assert false

  describe "When I POST no blueprint", ->
    it "I get HTTP 400", -> assert false
    it "I get an error", -> assert false  # within parseresult

  describe "When I POST an invalid blueprint", ->
    it "I get HTTP 400", -> assert false
    it "I get an error", -> assert false


describe "Composing", ->

  describe "When I send OPTIONS", ->
    it "I get HTTP 204", -> assert false
    it "I get CORS headers", -> assert false
    it "I get empty response body", -> assert false
    it "I get the right Accept header", -> assert false

  describe "When I send HEAD", ->
    it "I get HTTP 405", -> assert false
    it "I get empty response body", -> assert false
    it "I get the right Accept header", -> assert false

  describe "When I send GET", ->
    it "I get HTTP 405", -> assert false
    it "I get empty response body", -> assert false
    it "I get the right Accept header", -> assert false

  describe "When I POST a JSON AST, accepting whatever", ->
    it "I get HTTP 200", -> assert false
    it "I get CORS headers", -> assert false
    it "I get the right blueprint", -> assert false
    it "I get X-Composer-Time header", -> assert false
    it "I get the right Markdown Content-Type, with charset", -> assert false

  describe "When I POST an AST declaring it's in UTF-8, accepting whatever", ->
    it "I get HTTP 200", -> assert false

  describe "When I POST an AST declaring it's in non-UTF-8, accepting whatever", ->
    it "I get HTTP 415", -> assert false

  describe "When I POST an AST, accepting UTF-8 charset", ->
    it "I get HTTP 200", -> assert false

  describe "When I POST an AST, accepting non-UTF-8 charset", ->
    it "I get HTTP 406", -> assert false

  describe "When I POST a JSON AST declaring it's JSON", ->
    it "I get HTTP 200", -> assert false
    it "I get the right blueprint", -> assert false
    it "I get the right Markdown Content-Type, with charset", -> assert false

  describe "When I POST an YAML AST declaring it's YAML", ->
    it "I get HTTP 200", -> assert false
    it "I get the right blueprint", -> assert false
    it "I get the right Markdown Content-Type, with charset", -> assert false

  describe "When I POST no AST", ->
    it "I get HTTP 400", -> assert false
    it "I get an error", -> assert false

  describe "When I POST an invalid AST", ->
    it "I get HTTP 400", -> assert false
    it "I get an error", -> assert false
