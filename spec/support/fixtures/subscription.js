module.exports = subscription = 
[
  {
    "method": "SetExpressCheckout",
    "request": {
      "l_billingtype0": "RecurringPayments",
      "l_billingagreementdescription0": "2 loaves of bread billed weekly for $10",
      "paymentrequest_0_amt": 0,
      "maxamt": 10,
      "noshipping": 1,
      "allownote": 0,
      "returnurl": "https://www.goodeggsinc.com/order/dddd?_paypalpayment=success",
      "cancelurl": "https://www.goodeggsinc.com/order/ccxcx"
    },
    "response": {
      "token": "EC-944279568Y507670E",
      "timestamp": "2012-02-10T19:39:12Z",
      "correlationid": "7dddc6dcd9090",
      "ack": "Success",
      "version": "85.0",
      "build": "2515991"
    }
  },
  {
    "method": "getExpressCheckoutDetails",
    "request": {
      "_paypalpayment": "success",
      "token": "EC-944279568Y507670E"
    },
    "response": {
      "token": "EC-944279568Y507670E",
      "billingagreementacceptedstatus": "1",
      "checkoutstatus": "PaymentActionNotInitiated",
      "timestamp": "2012-02-10T19:39:51Z",
      "correlationid": "e1143e6566792",
      "ack": "Success",
      "version": "85.0",
      "build": "2515991",
      "email": "randy_1328687427_per@goodeggsinc.com",
      "payerid": "BYH8D7DV8KGG2",
      "payerstatus": "verified",
      "firstname": "Randy",
      "lastname": "Buyer",
      "countrycode": "US",
      "currencycode": "USD",
      "amt": "0.00",
      "shippingamt": "0.00",
      "handlingamt": "0.00",
      "taxamt": "0.00",
      "insuranceamt": "0.00",
      "shipdiscamt": "0.00",
      "paymentrequest_0_currencycode": "USD",
      "paymentrequest_0_amt": "0.00",
      "paymentrequest_0_shippingamt": "0.00",
      "paymentrequest_0_handlingamt": "0.00",
      "paymentrequest_0_taxamt": "0.00",
      "paymentrequest_0_insuranceamt": "0.00",
      "paymentrequest_0_shipdiscamt": "0.00",
      "paymentrequest_0_insuranceoptionoffered": "false",
      "paymentrequestinfo_0_errorcode": "0"
    }
  },
  {
    "method": "CreateRecurringPaymentsProfile",
    "request": {
      "profilestartdate": "2012-02-15T12:00:00Z",
      "profilestartreference": "subscriptionId",
      "desc": "2 loaves of bread billed weekly for $10",
      "billingperiod": "Week",
      "billingfrequency": "1",
      "amt": 10,
      "currencycode": "USD",
      "_paypalpayment": "success",
      "token": "EC-944279568Y507670E"
    },
    "response": {
      "profileid": "I-7EBXRULMEV58",
      "profilestatus": "ActiveProfile",
      "timestamp": "2012-02-10T19:39:54Z",
      "correlationid": "61e7920e5d29a",
      "ack": "Success",
      "version": "85.0",
      "build": "2562906"
    }
  }
];

subscription.setExpressCheckout = subscription[0];
subscription.getExpressCheckoutDetails = subscription[1];
subscription.createRecurringPaymentsProfile = subscription[2];

subscription.redirectUrl = "https://www.goodeggsinc.com/order/return?_paypalpayment=success&token=EC-944279568Y507670E";
