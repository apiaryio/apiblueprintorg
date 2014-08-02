{assert} = require 'chai'
typer = require 'media-typer'


exports.assertHeaderExists = (res, name) ->
  # res is an instance of IncomingMessage and the docs claim that
  # names of its headers are lowercased: http://nodejs.org/api/http.html#http_message_headers
  assert.ok res.headers[name.toLowerCase()]


exports.assertHeaderEquals = (res, name, value) ->
  # res is an instance of IncomingMessage and the docs claim that
  # names of its headers are lowercased: http://nodejs.org/api/http.html#http_message_headers
  name = name.toLowerCase()

  realValue = res.headers[name]
  if not realValue
    return assert.notOk value

  if name isnt 'content-type'
    return assert.equal realValue, value

  parts = typer.parse value
  realParts = typer.parse realValue
  assert.deepEqual parts, realParts
