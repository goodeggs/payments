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

    options = requestStub.lastCall.args[0]
    cb = requestStub.lastCall.args[1]

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
    requestStub.callsArgWith 1, null,
      statusCode: 500

    paypal.request 'SetExpressCheckout', {paymentrequest_0_amt: 29.99}, (err, result) ->
      err.message.should.match /500/
      err.message.should.match /https:\/\/api-3t.sandbox.paypal.com\/nvp/
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
      body: 'TOKEN=EC%2d4L057467UU893972F&TIMESTAMP=2012%2d02%2d08T08%3a18%3a43Z&CORRELATIONID=1c1401273ec37&ACK=Success&VERSION=85%2e0&BUILD=2515991'

    paypal.request 'SetExpressCheckout', {paymentrequest_0_amt: 29.99}, (err, result) ->
      result.token.should.equal 'EC-4L057467UU893972F'
      result.timestamp.should.equal '2012-02-08T08:18:43Z'
      result.correlationid.should.equal '1c1401273ec37'
      result.ack.should.equal 'Success'
      result.version.should.equal '85.0'
      result.build.should.equal '2515991'
      done()

describe 'setExpressCheckout', ->
  afterEach ->
    sinon.restore()

  it 'returns a paypal payment url url', (done) ->
    params = {}
    
    mock = sinon.mock(paypal)
    mock.expects('request').withArgs('SetExpressCheckout', params).callsArgWith 2, null,
      token: 'EC-4L057467UU893972F'
      timestamp: '2012-02-08T08:18:43Z'
      correlationid: '1c1401273ec37'
      ack: 'Success'
      version: '85.0'
      build: '2515991'

    paypal.setExpressCheckout params, (err, result) ->
      result.should.equal 'https://www.sandbox.paypal.com/webscr?cmd=_express-checkout&token=EC-4L057467UU893972F'
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
