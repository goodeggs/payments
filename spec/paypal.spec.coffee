url = require 'url'
request = require 'request'
should = require 'should'
sinon = require('sinon').sandbox.create()
paypal = require('../src/paypal')

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
  requestStub = null
  logStub = null

  beforeEach ->
    paypal.reset()
    paypal.configure
      user: 'user_api1.domain.com',
      pwd: 'someApiPassword',
      signature: 'signature123'

    requestStub = sinon.stub(request, 'post')
    logStub = sinon.stub(paypal, 'log')

  afterEach ->
    sinon.restore()

  it 'logs the sterilized request', ->
    paypal.request 'SetExpressCheckout', {paymentrequest_0_amt: 29.99}, (err, result) ->
      #do nothing

    logStub.lastCall.args[0].should.equal 'log'
    for arg in logStub.lastCall.args
      JSON.stringify(arg).should.not.match /someApiPassword/
      JSON.stringify(arg).should.not.match /signature123/

  it 'creates a POST with all params in the URL', ->

    paypal.request 'SetExpressCheckout', {paymentrequest_0_amt: 29.99}, (err, result) ->
      #do nothing

    callUrl = requestStub.lastCall.args[0]
    cb = requestStub.lastCall.args[1]

    callUrl = url.parse(callUrl, true)
    callUrl.href.should.match /^https:\/\/api-3t.sandbox.paypal.com\/nvp\?/
    callUrl.query.USER.should.equal 'user_api1.domain.com'
    callUrl.query.PWD.should.equal 'someApiPassword'
    callUrl.query.SIGNATURE.should.equal 'signature123'
    callUrl.query.METHOD.should.equal 'SetExpressCheckout'
    callUrl.query.PAYMENTREQUEST_0_AMT.should.equal '29.99'
    callUrl.query.VERSION.should.equal '85.0'

  it 'throws an error for a non 200 response', (done) ->
    requestStub.callsArgWith 1, null,
      statusCode: 500

    paypal.request 'SetExpressCheckout', {paymentrequest_0_amt: 29.99}, (err, result) ->
      err.message.should.match /500/
      err.message.should.match /https:\/\/api-3t.sandbox.paypal.com\/nvp\?/
      done()

  it 'returns an error for an error callback', (done) ->
    requestStub.callsArgWith 1, new Error('BOOM')

    paypal.request 'SetExpressCheckout', {paymentrequest_0_amt: 29.99}, (err, result) ->
      err.message.should.match /BOOM/
      done()

  it 'returns an error for a Failure response', (done) ->
    requestStub.callsArgWith 1, null,
        statusCode: 200
        body: 'TIMESTAMP=2012%2d02%2d08T04%3a23%3a39Z&CORRELATIONID=cd65742d7142d&ACK=Failure&L_ERRORCODE0=10001&L_SHORTMESSAGE0=Internal%20Error&L_LONGMESSAGE0=Timeout%20processing%20request'

    paypal.request 'SetExpressCheckout', {paymentrequest_0_amt: 29.99}, (err, result) ->
      err.message.should.equal '[Paypal Failure ref cd65742d7142d] Internal Error(10001): Timeout processing request'

      logStub.lastCall.args[0].should.equal 'error'
      logStub.lastCall.args[2].l_errorcode0.should.not.be.empty

      done()


  it 'returns a url decoded hash of the response body with lower case keys', (done) ->
    requestStub.callsArgWith 1, null,
      statusCode: 200
      body: 'TIMESTAMP=2012%2d02%2d08T04%3a23%3a39Z&CORRELATIONID=cd65742d7142d&ACK=Success&L_ERRORCODE0=10001&L_SHORTMESSAGE0=Internal%20Error&L_LONGMESSAGE0=Timeout%20processing%20request'

    paypal.request 'SetExpressCheckout', {paymentrequest_0_amt: 29.99}, (err, result) ->
      result.timestamp.should.equal '2012-02-08T04:23:39Z'
      result.correlationid.should.equal 'cd65742d7142d'
      result.ack.should.equal 'Success'
      result.l_errorcode0.should.equal '10001'
      result.l_shortmessage0.should.equal 'Internal Error'
      result.l_longmessage0.should.equal 'Timeout processing request'
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
  sterilized = paypal.sterilizeRequestForLogging
    user: 'user_api1.domain.com',
    pwd: 'someApiPassword',
    signature: 'signature123'

  sterilized.should.eql
    user: 'user_api1.domain.com',
    pwd: '[HIDDEN]',
    signature: '[HIDDEN]'

#describe 'actually call it', ->
#  beforeEach ->
#    paypal.reset()
#    paypal.configure
#        user: 'vendor_1328687313_biz_api1.goodeggsinc.com'
#        pwd: '1328687337'
#        signature: 'Aw2qKukXefVCgrC10z6yiJluFBhcAMIy8OAEc1uLo8dRWiFBN8CpawZ3'
#
#  it 'calls paypal!', (done) ->
#      paypal.request 'SetExpressCheckout', {
#        paymentrequest_0_amt: 29.99
#        paymentrequest_0_paymentaction: 'Sale'
#        returnurl: 'https://www.goodeggsinc.com/order/dddd'
#        cancelurl: 'https://www.goodeggsinc.com/order/ccxcx'
#      }, (err, result) ->
#        console.log("RESULT: ", result)
#        done(err)
