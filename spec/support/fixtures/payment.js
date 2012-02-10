module.exports = payment = 
[
  {
    "method": "SetExpressCheckout",
    "request": {
      "noshipping": 1,
      "allownote": 0,
      "paymentrequest_0_desc": "bread purchase",
      "paymentrequest_0_inv": "orderIdabc",
      "paymentrequest_0_amt": 10,
      "paymentrequest_0_paymentaction": "Sale",
      "l_paymentrequest_0_name0": "Parmesan Walnut",
      "l_paymentrequest_0_number0": "someLongProductNum12345",
      "l_paymentrequest_0_desc0": "a yummy loaf",
      "l_paymentrequest_0_amt0": 5,
      "l_paymentrequest_0_qty0": 2,
      "returnurl": "https://www.goodeggsinc.com/order/return?_paypalpayment=success",
      "cancelurl": "https://www.goodeggsinc.com/order/cancel"
    },
    "response": {
      "token": "EC-0TC963868H131830Y",
      "timestamp": "2012-02-10T19:42:02Z",
      "correlationid": "f2cd53aa7e789",
      "ack": "Success",
      "version": "85.0",
      "build": "2515991"
    }
  },
  {
    "method": "GetExpressCheckoutDetails",
    "request": {
      "_paypalpayment": "success",
      "token": "EC-0TC963868H131830Y",
      "PayerID": "BYH8D7DV8KGG2"
    },
    "response": {
      "token": "EC-0TC963868H131830Y",
      "checkoutstatus": "PaymentActionNotInitiated",
      "timestamp": "2012-02-10T19:42:32Z",
      "correlationid": "b8241393a0026",
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
      "amt": "10.00",
      "itemamt": "10.00",
      "shippingamt": "0.00",
      "handlingamt": "0.00",
      "taxamt": "0.00",
      "desc": "bread purchase",
      "insuranceamt": "0.00",
      "shipdiscamt": "0.00",
      "l_name0": "Parmesan Walnut",
      "l_number0": "someLongProductNum12345",
      "l_qty0": "2",
      "l_taxamt0": "0.00",
      "l_amt0": "5.00",
      "l_desc0": "a yummy loaf",
      "l_itemweightvalue0": "   0.00000",
      "l_itemlengthvalue0": "   0.00000",
      "l_itemwidthvalue0": "   0.00000",
      "l_itemheightvalue0": "   0.00000",
      "paymentrequest_0_currencycode": "USD",
      "paymentrequest_0_amt": "10.00",
      "paymentrequest_0_itemamt": "10.00",
      "paymentrequest_0_shippingamt": "0.00",
      "paymentrequest_0_handlingamt": "0.00",
      "paymentrequest_0_taxamt": "0.00",
      "paymentrequest_0_desc": "bread purchase",
      "paymentrequest_0_insuranceamt": "0.00",
      "paymentrequest_0_shipdiscamt": "0.00",
      "paymentrequest_0_insuranceoptionoffered": "false",
      "l_paymentrequest_0_name0": "Parmesan Walnut",
      "l_paymentrequest_0_number0": "someLongProductNum12345",
      "l_paymentrequest_0_qty0": "2",
      "l_paymentrequest_0_taxamt0": "0.00",
      "l_paymentrequest_0_amt0": "5.00",
      "l_paymentrequest_0_desc0": "a yummy loaf",
      "l_paymentrequest_0_itemweightvalue0": "   0.00000",
      "l_paymentrequest_0_itemlengthvalue0": "   0.00000",
      "l_paymentrequest_0_itemwidthvalue0": "   0.00000",
      "l_paymentrequest_0_itemheightvalue0": "   0.00000",
      "paymentrequestinfo_0_errorcode": "0"
    }
  },
  {
    "method": "DoExpressCheckoutPayment",
    "request": {
      "paymentrequest_0_amt": 10,
      "_paypalpayment": "success",
      "token": "EC-0TC963868H131830Y",
      "PayerID": "BYH8D7DV8KGG2"
    },
    "response": {
      "token": "EC-0TC963868H131830Y",
      "successpageredirectrequested": "false",
      "timestamp": "2012-02-10T19:42:37Z",
      "correlationid": "6f4ec10bd5de3",
      "ack": "Success",
      "version": "85.0",
      "build": "2515991",
      "insuranceoptionselected": "false",
      "shippingoptionisdefault": "false",
      "paymentinfo_0_transactionid": "6GE959348X2815629",
      "paymentinfo_0_transactiontype": "expresscheckout",
      "paymentinfo_0_paymenttype": "instant",
      "paymentinfo_0_ordertime": "2012-02-10T19:42:35Z",
      "paymentinfo_0_amt": "10.00",
      "paymentinfo_0_feeamt": "0.59",
      "paymentinfo_0_taxamt": "0.00",
      "paymentinfo_0_currencycode": "USD",
      "paymentinfo_0_paymentstatus": "Completed",
      "paymentinfo_0_pendingreason": "None",
      "paymentinfo_0_reasoncode": "None",
      "paymentinfo_0_protectioneligibility": "Ineligible",
      "paymentinfo_0_protectioneligibilitytype": "None",
      "paymentinfo_0_securemerchantaccountid": "MZ9SP6U2CWXKS",
      "paymentinfo_0_errorcode": "0",
      "paymentinfo_0_ack": "Success"
    }
  }
];

payment.setExpressCheckout = payment[0];
payment.getExpressCheckoutDetails = payment[1];
payment.doExpressCheckoutPayment = payment[2];

payment.redirectUrl = "https://www.goodeggsinc.com/order/return?_paypalpayment=success&token=EC-0TC963868H131830Y&PayerID=BYH8D7DV8KGG2";
