url = require 'url'
request = require 'request'
paypal = require('../src/paypal')
fixtures =
  payment: require './support/fixtures/payment'
  subscription: require './support/fixtures/subscription'

describe 'configure', ->

  beforeEach ->
    paypal.reset()

  it 'requires configuration', (done) ->
    paypal.configure()
    paypal.request 'SetExpressCheckout', (err, result) ->
      expect(err.message).toMatch /configure/
      expect(err.message).toMatch /user/
      expect(err.message).toMatch /pwd/
      expect(err.message).toMatch /signature/
      done()

  it 'has a default apiUrl', ->
    paypal.configure()
    expect(paypal.apiUrl).toEqual 'https://api-3t.sandbox.paypal.com/nvp'


  it 'allows changing the apiUrl', ->
    paypal.configure(apiUrl: 'https://someotherurl/')
    expect(paypal.options.apiUrl).toEqual 'https://someotherurl/'


describe 'request', ->
  beforeEach ->
    paypal.reset()
    paypal.configure
      user: 'user_api1.domain.com',
      pwd: 'someApiPassword',
      signature: 'signature123'

      spyOn(request, 'post')
      spyOn(paypal, 'log')

  it 'logs the sterilized request', ->
    paypal.request 'SetExpressCheckout', {paymentrequest_0_amt: 29.99}, (err, result) ->
      #do nothing

    expect(paypal.log.mostRecentCall.args[0]).toEqual 'log'
    for arg in paypal.log.mostRecentCall.args
      expect(JSON.stringify(arg)).not.toMatch /someApiPassword/
      expect(JSON.stringify(arg)).not.toMatch /signature123/

  it 'creates a POST with all params in the URL', ->

    paypal.setExpressCheckout {paymentrequest_0_amt: 29.99}, (err, result) ->
      #do nothing

    options = request.post.mostRecentCall.args[0]
    cb = request.post.mostRecentCall.args[1]

    callUrl = url.parse(options.url, true)
    expect(callUrl.href).toEqual 'https://api-3t.sandbox.paypal.com/nvp'
    
    expect(options.form.USER).toEqual 'user_api1.domain.com'
    expect(options.form.PWD).toEqual 'someApiPassword'
    expect(options.form.SIGNATURE).toEqual 'signature123'
    expect(options.form.METHOD).toEqual 'SetExpressCheckout'
    expect(options.form.PAYMENTREQUEST_0_AMT).toEqual 29.99
    expect(options.form.VERSION).toEqual '85.0'
    expect(options.form.APIURL).toBeUndefined()

  it 'throws an error for a non 200 response', (done) ->
    request.post.andCallFake (params, cb) ->
      cb null,
        statusCode: 500

    paypal.setExpressCheckout {paymentrequest_0_amt: 29.99}, (err, result) ->
      expect(err.message).toMatch /500/
      expect(err.message).toMatch /https:\/\/api-3t.sandbox.paypal.com\/nvp/
      done()

  it 'returns an error for an error callback', (done) ->
    request.post.andCallFake (params, cb) ->
      cb new Error('BOOM')

    paypal.setExpressCheckout {paymentrequest_0_amt: 29.99}, (err, result) ->
      expect(err.message).toMatch /BOOM/
      done()

  it 'returns an error for a Failure response', (done) ->
    request.post.andCallFake (params, cb) ->
      cb null,
        statusCode: 200
        body: 'TIMESTAMP=2012%2d02%2d08T04%3a23%3a39Z&CORRELATIONID=cd65742d7142d&ACK=Failure&L_ERRORCODE0=10001&L_SHORTMESSAGE0=Internal%20Error&L_LONGMESSAGE0=Timeout%20processing%20request'

    paypal.setExpressCheckout {paymentrequest_0_amt: 29.99}, (err, result) ->
      expect(err.message).toEqual '[Paypal Failure ref cd65742d7142d] Internal Error(10001): Timeout processing request'

      expect(paypal.log.mostRecentCall.args[0]).toEqual 'error'
      expect(paypal.log.mostRecentCall.args[2].l_errorcode0).toBeDefined()

      done()


  it 'returns a url decoded hash of the response body with lower case keys', (done) ->
    request.post.andCallFake (params, cb) ->
      cb null,
        statusCode: 200
        body: 'TOKEN=EC%2d4L057467UU893972F&TIMESTAMP=2012%2d02%2d08T08%3a18%3a43Z&CORRELATIONID=1c1401273ec37&ACK=Success&VERSION=85%2e0&BUILD=2515991'

    paypal.setExpressCheckout {paymentrequest_0_amt: 29.99}, (err, result) ->
      expect(result.token).toEqual 'EC-4L057467UU893972F'
      expect(result.timestamp).toEqual '2012-02-08T08:18:43Z'
      expect(result.correlationid).toEqual '1c1401273ec37'
      expect(result.ack).toEqual 'Success'
      expect(result.version).toEqual '85.0'
      expect(result.build).toEqual '2515991'
      done()

describe 'API methods', ->
  beforeEach ->
    paypal.reset()
    paypal.configure()

  it 'passes the correct method name to request', ->
    params = {}
    cb = ->

    spyOn(paypal, 'request')

    paypal.setExpressCheckout(params, cb)
    expect(paypal.request.mostRecentCall.args).toEqual ['SetExpressCheckout', params, cb]

describe 'startPaymentFlow', ->
  beforeEach ->
    paypal.reset()
    paypal.configure()

  it 'returns a paypal payment url', (done) ->
    params =
      returnurl: 'http://localhost:3001/order/123456'
    
    spyOn(paypal, 'request').andCallFake (method, params, cb) ->
      expect(method).toEqual 'SetExpressCheckout'
      expect(params).toEqual
        returnurl: 'http://localhost:3001/order/123456?_paypalpayment=success'
      cb null, fixtures.payment.setExpressCheckout.response

    paypal.startPaymentFlow params, (err, result) ->
      expect(result).toEqual "https://www.sandbox.paypal.com/webscr?cmd=_express-checkout&useraction=commit&token=#{fixtures.payment.setExpressCheckout.response.token}"
      done()

describe 'buildErrorMessage', ->
  it 'contains the error fields', ->
    response =
      correlationid: 'cd65742d7142d'
      ack: 'Failure'
      l_errorcode0: '10001'
      l_shortmessage0: 'Internal Error'
      l_longmessage0: 'Timeout processing request'

    expect(paypal.buildErrorMessage(response)).toEqual '[Paypal Failure ref cd65742d7142d] Internal Error(10001): Timeout processing request'

  it 'contains multiple errors', ->
    response =
      correlationid: 'cd65742d7142d'
      ack: 'Failure'
      l_errorcode0: '10001'
      l_shortmessage0: 'Internal Error'
      l_longmessage0: 'Timeout processing request'
      l_errorcode1: '10002'
      l_shortmessage1: 'Other Error'
      l_longmessage1: 'Some other error'
      l_severitycode1: 'err'

    expect(paypal.buildErrorMessage(response)).toEqual '[Paypal Failure ref cd65742d7142d] Internal Error(10001): Timeout processing request; Other Error(10002): Some other error - err'

describe 'parseLists', ->
  it 'should break down L_ fields', ->
    response =
      correlationid: 'cd65742d7142d'
      ack: 'Failure'
      l_errorcode0: '10001'
      l_shortmessage0: 'Internal Error'
      l_longmessage0: 'Timeout processing request'
      l_errorcode1: '10002'
      l_shortmessage1: 'Other Error'
      l_longmessage1: 'Some other error'
      l_severitycode1: 'err'

    lists = paypal.parseLists(response)
    expect(lists.length).toEqual 2
    expect(lists[0]).toEqual
      errorcode: '10001'
      shortmessage: 'Internal Error'
      longmessage: 'Timeout processing request'
    expect(lists[1]).toEqual
      errorcode: '10002'
      shortmessage: 'Other Error'
      longmessage: 'Some other error'
      severitycode: 'err'

describe 'sterilizeRequestForLogging', ->
  it 'should hide sensitive details', ->
    sterilized = paypal.sterilizeRequestForLogging
      user: 'user_api1.domain.com',
      pwd: 'someApiPassword',
      signature: 'signature123'

    expect(sterilized).toEqual
      user: 'user_api1.domain.com',
      pwd: '[HIDDEN]',
      signature: '[HIDDEN]'
