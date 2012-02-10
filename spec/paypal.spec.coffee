url = require 'url'
request = require 'request'
should = require 'should'
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
      err.message.should.match /configure/
      err.message.should.match /user/
      err.message.should.match /pwd/
      err.message.should.match /signature/
      done()

  it 'allows has a default apiUrl', ->
    paypal.options.apiUrl.should.equal 'https://api-3t.sandbox.paypal.com/nvp'


  it 'allows changing the apiUrl', ->
    paypal.configure(apiUrl: 'https://someotherurl/')
    paypal.options.apiUrl.should.equal 'https://someotherurl/'

  it 'does not allow you to unset the api url', (done) ->
    paypal.configure(apiUrl: '    ')

    paypal.request 'SetExpressCheckout', (err, result) ->
      err.message.should.match /configure/
      err.message.should.match /apiUrl/
      done()


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

    paypal.log.mostRecentCall.args[0].should.equal 'log'
    for arg in paypal.log.mostRecentCall.args
      JSON.stringify(arg).should.not.match /someApiPassword/
      JSON.stringify(arg).should.not.match /signature123/

  it 'creates a POST with all params in the URL', ->

    paypal.setExpressCheckout {paymentrequest_0_amt: 29.99}, (err, result) ->
      #do nothing

    options = request.post.mostRecentCall.args[0]
    cb = request.post.mostRecentCall.args[1]

    callUrl = url.parse(options.url, true)
    callUrl.href.should.equal 'https://api-3t.sandbox.paypal.com/nvp'
    
    options.form.USER.should.equal 'user_api1.domain.com'
    options.form.PWD.should.equal 'someApiPassword'
    options.form.SIGNATURE.should.equal 'signature123'
    options.form.METHOD.should.equal 'SetExpressCheckout'
    options.form.PAYMENTREQUEST_0_AMT.should.equal 29.99
    options.form.VERSION.should.equal '85.0'
    should.not.exist(options.form.APIURL)

  it 'throws an error for a non 200 response', (done) ->
    request.post.andCallFake (params, cb) ->
      cb null,
        statusCode: 500

    paypal.setExpressCheckout {paymentrequest_0_amt: 29.99}, (err, result) ->
      err.message.should.match /500/
      err.message.should.match /https:\/\/api-3t.sandbox.paypal.com\/nvp/
      done()

  it 'returns an error for an error callback', (done) ->
    request.post.andCallFake (params, cb) ->
      cb new Error('BOOM')

    paypal.setExpressCheckout {paymentrequest_0_amt: 29.99}, (err, result) ->
      err.message.should.match /BOOM/
      done()

  it 'returns an error for a Failure response', (done) ->
    request.post.andCallFake (params, cb) ->
      cb null,
        statusCode: 200
        body: 'TIMESTAMP=2012%2d02%2d08T04%3a23%3a39Z&CORRELATIONID=cd65742d7142d&ACK=Failure&L_ERRORCODE0=10001&L_SHORTMESSAGE0=Internal%20Error&L_LONGMESSAGE0=Timeout%20processing%20request'

    paypal.setExpressCheckout {paymentrequest_0_amt: 29.99}, (err, result) ->
      err.message.should.equal '[Paypal Failure ref cd65742d7142d] Internal Error(10001): Timeout processing request'

      paypal.log.mostRecentCall.args[0].should.equal 'error'
      paypal.log.mostRecentCall.args[2].l_errorcode0.should.not.be.empty

      done()


  it 'returns a url decoded hash of the response body with lower case keys', (done) ->
    request.post.andCallFake (params, cb) ->
      cb null,
        statusCode: 200
        body: 'TOKEN=EC%2d4L057467UU893972F&TIMESTAMP=2012%2d02%2d08T08%3a18%3a43Z&CORRELATIONID=1c1401273ec37&ACK=Success&VERSION=85%2e0&BUILD=2515991'

    paypal.setExpressCheckout {paymentrequest_0_amt: 29.99}, (err, result) ->
      result.token.should.equal 'EC-4L057467UU893972F'
      result.timestamp.should.equal '2012-02-08T08:18:43Z'
      result.correlationid.should.equal '1c1401273ec37'
      result.ack.should.equal 'Success'
      result.version.should.equal '85.0'
      result.build.should.equal '2515991'
      done()

describe 'API methods', ->
  it 'passes the correct method name to request', ->
    params = {}
    cb = ->

    spyOn(paypal, 'request')

    paypal.setExpressCheckout(params, cb)
    paypal.request.mostRecentCall.args.should.eql ['SetExpressCheckout', params, cb]

describe 'startPaymentFlow', ->
  it 'returns a paypal payment url', (done) ->
    params =
      returnurl: 'http://localhost:3001/order/123456'
    
    spyOn(paypal, 'request').andCallFake (method, params, cb) ->
      method.should.equal 'SetExpressCheckout'
      params.should.eql
        returnurl: 'http://localhost:3001/order/123456?_paypalpayment=success'
      cb null, fixtures.payment.setExpressCheckout.response

    paypal.startPaymentFlow params, (err, result) ->
      result.should.equal "https://www.sandbox.paypal.com/webscr?cmd=_express-checkout&useraction=commit&token=#{fixtures.payment.setExpressCheckout.response.token}"
      done()

describe 'buildErrorMessage', ->
  it 'contains the error fields', ->
    response =
      correlationid: 'cd65742d7142d'
      ack: 'Failure'
      l_errorcode0: '10001'
      l_shortmessage0: 'Internal Error'
      l_longmessage0: 'Timeout processing request'

    paypal.buildErrorMessage(response).should.equal '[Paypal Failure ref cd65742d7142d] Internal Error(10001): Timeout processing request'

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

    paypal.buildErrorMessage(response).should.equal '[Paypal Failure ref cd65742d7142d] Internal Error(10001): Timeout processing request; Other Error(10002): Some other error - err'

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
    lists.length.should.equal 2
    lists[0].should.eql
      errorcode: '10001'
      shortmessage: 'Internal Error'
      longmessage: 'Timeout processing request'
    lists[1].should.eql
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

    sterilized.should.eql
      user: 'user_api1.domain.com',
      pwd: '[HIDDEN]',
      signature: '[HIDDEN]'
