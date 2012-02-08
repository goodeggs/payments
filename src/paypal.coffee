qs = require 'querystring'
request = require 'request'

required = ['apiUrl', 'user', 'pwd', 'signature']
defaults =
  apiUrl: process.env.NODE_ENV is 'production' and 'https://api-3t.paypal.com/nvp' or 'https://api-3t.sandbox.paypal.com/nvp'
  version: '85.0'

module.exports = paypal =
  options: Object.create(defaults)

  configure: (opts = {}) ->
    paypal.options[key] = value for key, value of opts

  reset: ->
    paypal.options = Object.create(defaults)

  request: (method, params, cb) ->
    if typeof params is 'function'
      cb = params
      params = {}

    requestParams = {}
    for settingsObj in [{method: method}, paypal.options, params]
      requestParams[key] = value for key, value of settingsObj

    missing = (key for key in required when not requestParams[key]?.trim())
    return cb(new Error("you must configure paypal with #{missing.join(', ')}")) if missing.length isnt 0

    paypal.log('log', 'Paypal request', paypal.sterilizeRequestForLogging(requestParams))

    url = "#{requestParams.apiUrl}?"
    delete requestParams.apiUrl

    upperCaseRequest = {}
    upperCaseRequest[key.toUpperCase()] = value for key, value of requestParams
    url += qs.stringify(upperCaseRequest)

    request.post url, (err, httpResponse) ->
      return cb(err) if err
      return cb(new Error("Unexpected #{httpResponse.statusCode} response from POST to #{url}")) unless httpResponse.statusCode is 200

      response = {}
      response[key.toLowerCase()] = value for key, value of qs.parse(httpResponse.body)

      #log the result
      paypal.log(response.ack is 'Success' and 'log' or 'error', "Paypal #{response.ack}", response)

      switch response.ack
        when 'Success'
          cb(null, response)
        when 'SuccessWithWarning'
          cb(null, response)
        when 'Failure', 'FailureWithWarning'
          cb(new Error(paypal.buildErrorMessage(response)))
        else
          cb(new Error("Unknown paypal ack #{response.ack}"))

  parseLists: (response) ->
    result = []
    for key, value of response
      if match = key.match /^l_(.*)(\d+)$/
        (result[parseInt(match[2])] ?= {})[match[1]] = value
    result

  buildErrorMessage: (response) ->
    lists = paypal.parseLists(response)
    errors = ("#{item.shortmessage}(#{item.errorcode}): #{item.longmessage}#{item.severitycode and " - #{item.severitycode}" or ''}" for item in lists when item.errorcode)
    "[Paypal #{response.ack} ref #{response.correlationid}] #{errors.join('; ')}"

  sterilizeRequestForLogging: (request) ->
    result = {}
    result[key] = (key.toLowerCase() in ['password', 'pwd', 'passwd', 'signature'] and '[HIDDEN]' or value) for key, value of request
    result

  #For stubbing
  log: (level, args...) ->
    console[level](args...)
