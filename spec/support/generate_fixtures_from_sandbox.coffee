#!/usr/bin/env coffee

paypal = require '../../lib/paypal.js'
rl = require 'readline'
exec = require('child_process').exec
url = require 'url'
fs = require 'fs'
path = require 'path'
_ = require 'underscore'

i = null
trace = []

setup = ->
  i = rl.createInterface(process.stdin, process.stdout, null)

  paypal.configure
      user: 'gdeggs_1328811359_biz_api1.goodeggsinc.com'
      pwd: '1328811383'
      signature: 'A-oK410gfkIfnnyXcB6T9JTIbJ1VAXQs7uCrqwyrh-emAQKVh2vRj9Zz'
      subject: 'vendor_1328687313_biz@goodeggsinc.com'

  originalRequest = paypal.request
  paypal.request = (method, params, cb) ->
    details =
      method: method
      request: params
    trace.push details

    originalRequest.call paypal, method, params, (err, response) ->
      details.response = err or response
      cb(err, response)

dumpFixture = (name, redirectUrl) ->
  fixtureStr = "module.exports = #{name} = \n" + JSON.stringify(trace, null, 2) + ";\n\n"
  for detail, i in trace
    fixtureStr += "#{name}.#{detail.method[0].toLowerCase() + detail.method[1..]} = #{name}[#{i}];\n"
  fixtureStr += "\n#{name}.redirectUrl = \"#{redirectUrl.href}\";\n"
  file = path.join(__dirname, "fixtures/#{name}.js")
  fs.writeFileSync(file, fixtureStr)
  console.log("updated #{file}")


startFlow = (params, cb) ->
  paypal.startPaymentFlow params, (err, href) ->
    throw err if err?
    i.question "We are going to open the payment url in your browser. Login with randy_1328687427_per@goodeggsinc.com, password 328687387. When payment has completed, you will be redirected to a failed page. Come back here and enter that redirect URL. Hit return to continue...", (answer) ->
      console.log("opening ", href)
      exec "open \"#{href}\"", ->

      i.question "What is the redirect URL?", (answer) ->
        i.close()
        process.stdin.destroy()

        redirectUrl = url.parse(answer, true)
        cb(null, redirectUrl)


doPayment = ->
  setup()
  orderAmt = 10

  startFlow
    noshipping: 1
    allownote: 0
    paymentrequest_0_desc: 'bread purchase'
    paymentrequest_0_inv: 'orderIdabc'
    paymentrequest_0_amt: orderAmt
    paymentrequest_0_paymentaction: 'Sale'
    l_paymentrequest_0_name0: 'Parmesan Walnut'
    l_paymentrequest_0_number0: 'someLongProductNum12345'
    l_paymentrequest_0_desc0: 'a yummy loaf'
    l_paymentrequest_0_amt0: 5
    l_paymentrequest_0_qty0: 2
    #brandname: overrides the business name
    #customerservicenumber - can be configured elsewhere
    returnurl: 'https://www.goodeggsinc.com/order/return'
    cancelurl: 'https://www.goodeggsinc.com/order/cancel'
  , (err, redirectUrl) ->
    throw err if err?
    paypal.getExpressCheckoutDetails redirectUrl.query, (err, result) ->
      throw err if err?
      paypal.doExpressCheckoutPayment _(paymentrequest_0_amt: orderAmt).extend(redirectUrl.query), (err, result) ->
        throw err if err?
        dumpFixture('payment', redirectUrl)

doSubscription = ->
  setup()

  recurringDescription = '2 loaves of bread billed weekly for $10'

  startFlow
    l_billingtype0: 'RecurringPayments'
    l_billingagreementdescription0: recurringDescription
    paymentrequest_0_amt: 0
    maxamt: 10
    noshipping: 1
    allownote: 0
    returnurl: 'https://www.goodeggsinc.com/order/return'
    cancelurl: 'https://www.goodeggsinc.com/order/cancel'
  , (err, redirectUrl) ->
    throw err if err?

    paypal.request 'getExpressCheckoutDetails', redirectUrl.query, (err, result) ->
      throw err if err?
      paypal.request 'CreateRecurringPaymentsProfile', _.extend({
        profilestartdate: '2012-02-15T12:00:00Z'
        profilestartreference: 'subscriptionId'
        desc: recurringDescription
        billingperiod: 'Week'
        billingfrequency: '1'
        amt: 10
        currencycode: 'USD'
        #subscribername: '' - defaults to paypal name?
        #email: 'randybuyer@gmail.com' - defaults to paypal email?
      }, redirectUrl.query), (err, result) ->
        throw err if err?
        dumpFixture('suscription', redirectUrl)

switch process.argv[2]
  when 'payment'
    doPayment()
  when 'subscription'
    doSubscription()
  else
    console.error("You must specify payment or subscription on the command line")
    process.exit(1)

