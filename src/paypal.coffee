qs = require 'querystring'
u = require 'url'
request = require 'request'
_ = require 'underscore'

API = [
  'AddressVerify'
  'BillOutstandingAmount'
  'Callback'
  'CreateRecurringPaymentsProfile'
  'DoAuthorization'
  'DoCapture'
  'DoDirectPayment'
  'DoExpressCheckoutPayment'
  'DoNonReferencedCredit'
  'DoReauthorization'
  'DoReferenceTransaction'
  'DoVoid'
  'GetBalance'
  'GetBillingAgreementCustomerDetails'
  'GetExpressCheckoutDetails'
  'GetRecurringPaymentsProfileDetails'
  'GetTransactionDetails'
  'ManageRecurringPaymentsProfileStatus'
  'ManagePendingTransactionStatus'
  'MassPayment'
  'RefundTransaction'
  'SetCustomerBillingAgreement'
  'SetExpressCheckout'
  'TransactionSearch'
  'UpdateRecurringPaymentsProfile'
]

required = ['user', 'pwd', 'signature']
defaults =
  version: '85.0'

module.exports = paypal =
  options: Object.create(defaults)

  configure: (opts = {}) ->
    production = opts.production or false
    delete opts.production

    paypal.paypalUrl = production and 'https://www.paypal.com/' or 'https://www.sandbox.paypal.com/'
    paypal.apiUrl = production and 'https://api-3t.paypal.com/nvp' or 'https://api-3t.sandbox.paypal.com/nvp'
    paypal.options[key] = value for key, value of opts

  reset: ->
    paypal.paypalUrl = null
    paypal.apiUrl = null
    paypal.options = Object.create(defaults)

  request: (method, params, cb) ->
    if typeof params is 'function'
      cb = params
      params = {}

    params = _({}).defaults(params, paypal.options, method: method)

    missing = (key for key in required when not params[key]?.trim())
    return cb(new Error("you must configure paypal with #{missing.join(', ')}")) if missing.length isnt 0

    paypal.log('Paypal request', paypal.sterilizeRequestForLogging(params))

    upperCaseRequest = {}
    upperCaseRequest[key.toUpperCase()] = value for key, value of params

    request.post {url: paypal.apiUrl, form: upperCaseRequest}, (err, httpResponse) ->
      return cb(err) if err?
      return cb(new Error("Unexpected #{httpResponse.statusCode} response from POST to #{paypal.apiUrl}")) unless httpResponse.statusCode is 200

      response = {}
      response[key.toLowerCase()] = value for key, value of qs.parse(httpResponse.body)

      #log the result
      paypal.log("Paypal response #{response.ack}", response)

      switch response.ack
        when 'Success'
          cb(null, response)
        when 'SuccessWithWarning'
          cb(null, response)
        when 'Failure', 'FailureWithWarning'
          cb(new Error(paypal.buildErrorMessage(response)))
        else
          cb(new Error("Unknown paypal ack #{response.ack}"))


  # Calls back with the paypal token which identifies the transaction and can be used to build an express checkout Url.
  startPaymentFlow: (params, cb) ->
    params = _.clone(params)
    returnUrl = u.parse(params.returnurl, true)
    returnUrl.query._paypalpayment = 'success'
    params.returnurl = u.format(returnUrl)

    paypal.request 'SetExpressCheckout', params, (err, response) ->
      return cb(err) if err?
      return cb(new Error("[Paypal ref #{response.correlationid}] missing expected token")) unless response.token

      cb(null, response.token)

  expressCheckoutUrl: (token) ->
    "#{paypal.paypalUrl}webscr?#{qs.stringify(cmd: '_express-checkout', useraction: 'commit', token: token)}"

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
  log: (args...) ->
    console.log(args...)

# Add methods for the given api names
for method in API
  do (method) ->
    paypal[method[0].toLowerCase() + method[1..]] = (args...) ->
      paypal.request(method, args...)
