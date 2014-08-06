# Configuration
config    = require '../config'

# Packages
express      = require 'express'
compression  = require 'compression'
errorHandler = require 'errorhandler'
logger       = require 'morgan'
yaml         = require 'js-yaml'
typer        = require 'media-typer'
qs           = require 'qs'

# Modules
blueprint = require '../blueprint'

# Logging
log       = require('../logging').get 'app/controllers/api'


# Constants
BUFFER_LIMIT      = parseInt(process.env.BUFFER_LIMIT, 10)
ORIGIN_REGEXP     = new RegExp "#{process.env.DOMAIN}".replace(/[\-{}\[\]+?.,\\\^$|#\s]/g, '\\$&') + "$"
APIARY_REGEXP     = new RegExp /apiary\.io$/
DEVELOP_REGEXP    = new RegExp /apiblueprint\.dev:([\d]{1,})$/


# Local functions
isDevelopmentMode = ->
  process.env.NODE_ENV is 'development'

normalizeNewlines = (s) ->
  s.replace(/\r\n/g, "\n").replace(/\r/g, "\n")

formatTime = (hrtime) ->
  # nano (1/1000) => micro (1/1000000) => ms
  hrtime[0] + ' s, ' + (hrtime[1] / 1000000).toFixed(0) + ' ms'

addCORS = (req, res, methods) ->
  res.set 'Access-Control-Allow-Credentials', 'true'
  res.set 'Access-Control-Allow-Methods', methods.join(', ') + ', OPTIONS'
  res.set 'Access-Control-Allow-Headers', 'Content-Type, Accept'
  res.set 'Access-Control-Expose-Headers', 'Content-Type, Accept'
  res.set 'Access-Control-Max-Age', 60 * 60 * 24

  origin = req.get('Origin') or ''
  if ORIGIN_REGEXP.test(origin) or APIARY_REGEXP.test(origin) or DEVELOP_REGEXP.test(origin)
    res.set 'Access-Control-Allow-Origin', origin
  else
    res.set 'Access-Control-Allow-Origin', process.env.DOMAIN

optionsHandler = () ->
  methods = (method.toUpperCase() for method in arguments)
  if 'OPTIONS' in methods
    methods.pop 'OPTIONS'

  (req, res, next) ->
    addCORS req, res, methods
    if req.method not in methods
      res.set 'Allow', methods.join(', ') + ', OPTIONS'
      return res.send (if req.method is 'OPTIONS' then 200 else 405), new Buffer ''
    next()

parseBody = (req, res, next) ->
  # Check Content-Type of the incoming data - in case it declares other
  # encoding than utf-8, we reject it with 415 Unsupported Media Type
  # (consulted the HTTP code with http://stackoverflow.com/a/11478530/325365).
  type = req.get 'content-type'
  if type
    charset = typer.parse(type).parameters.charset
    if charset and charset.replace('-', '').toLowerCase() isnt 'utf8'
      return sendError res,
        code: 415
        message: "Request body sent as #{charset}, but only utf-8 is supported."

  # ...otherwise (type or charset are missing) we just assume it's utf-8.
  req.setEncoding 'utf8'
  req.body = ''
  req.on 'data', (chunk) ->
    req.body += chunk
  req.on 'end', ->
    next()

sendJSON = (res, code, obj) ->
  if not res.get 'Content-Type'
    res.set 'Content-Type', 'application/json'
  res.send code or 200, new Buffer(if obj then JSON.stringify obj else '')

sendError = (res, {code, message, description}) ->
  err = {message}
  if description
    err.description = description
  sendJSON res, code or 400, err


# Setup
exports.setup = (app) ->
  app.set 'trust proxy', true  # trust headers like X-Forwarded-* for setting req.proto et al
  app.use compression(threshold: 512)

  # Setup development error handler.
  # Modify `NODE_ENV` environment variable to force the right scope.
  if isDevelopmentMode()
    app.use errorHandler
      dumpExceptions: true
      showStack: true
      fileUrls: 'txmt'
  else
    app.use logger 'tiny'


  app.all '/parser', optionsHandler('POST'), parseBody, (req, res) ->
    blueprintCode = normalizeNewlines req.body

    t = process.hrtime()
    blueprint.parse blueprintCode, (err, result) ->
      result.error ?= err or null
      result._version = '1.0'
      res.set 'X-Parser-Time', formatTime process.hrtime t
      res.statusCode = if result.error and result.error.code isnt 0 then 400 else 200

      accepted = req.accepts [
        'application/vnd.apiblueprint.parseresult.raw+json',
        'application/vnd.apiblueprint.parseresult.raw+yaml'
      ]

      if accepted is 'application/vnd.apiblueprint.parseresult.raw+yaml'
        res.set 'Content-Type', 'application/vnd.apiblueprint.parseresult.raw+yaml; version=1.0'
        body = yaml.safeDump JSON.parse JSON.stringify result  # https://github.com/nodeca/js-yaml/issues/132
      else
        res.set 'Content-Type', 'application/vnd.apiblueprint.parseresult.raw+json; version=1.0'
        body = JSON.stringify result

      res.send new Buffer body  # sending without charset parameter


  app.all '/composer', optionsHandler('POST'), parseBody, (req, res) ->
    if not req.body
      sendError res,
        message: 'No AST, nothing to compose.'
    else
      format = if req.is 'application/vnd.apiblueprint.ast.raw+yaml' then 'yaml' else 'json'
      ast = normalizeNewlines req.body

      t = process.hrtime()
      blueprint.compose ast, format, (err, blueprintCode) ->
        res.set 'X-Composer-Time', formatTime process.hrtime t

        if err
          if err instanceof blueprint.MatterCompilerError
            sendError res,
              code: 500
              message: 'Internal server error.'
          else
            sendError res,
              message: err.message
        else
          res.set 'Content-Type', 'text/vnd.apiblueprint+markdown; version=1A'
          res.send blueprintCode  # sending with charset=utf-8


  app.all '/', optionsHandler('GET', 'HEAD'), (req, res) ->
    res.set 'Content-Type', 'application/hal+json'
    res.set 'Link', '<http://docs.apiblueprintapi.apiary.io>; rel="profile"'

    body = undefined
    if req.method is 'GET'
      body =
        _links:
          self: {href: '/'}
          parse: {href: '/parser'}
          compose: {href: '/composer'}
    sendJSON res, 200, body


  # Setup production error handler returning JSON.
  # Modify `NODE_ENV` environment variable to force the right scope.
  app.use (err, req, res, next) ->
    if isDevelopmentMode()
      next()
    else
      sendError res,
        code: 500
        message: 'Internal server error.'
        description: err.message


  # HTTP 404 error handler. We're not serving any static files,
  # so this is okay.
  app.all '*', (req, res) ->
    sendError res,
      code: 404
      message: 'Specified resource was not found.'
