(function() {
  var API, defaults, method, paypal, paypalUrl, qs, request, required, u, _, _fn, _i, _len,
    __slice = Array.prototype.slice;

  qs = require('querystring');

  u = require('url');

  request = require('request');

  _ = require('underscore');

  API = ['AddressVerify', 'BillOutstandingAmount', 'Callback', 'CreateRecurringPaymentsProfile', 'DoAuthorization', 'DoCapture', 'DoDirectPayment', 'DoExpressCheckoutPayment', 'DoNonReferencedCredit', 'DoReauthorization', 'DoReferenceTransaction', 'DoVoid', 'GetBalance', 'GetBillingAgreementCustomerDetails', 'GetExpressCheckoutDetails', 'GetRecurringPaymentsProfileDetails', 'GetTransactionDetails', 'ManageRecurringPaymentsProfileStatus', 'ManagePendingTransactionStatus', 'MassPayment', 'RefundTransaction', 'SetCustomerBillingAgreement', 'SetExpressCheckout', 'TransactionSearch', 'UpdateRecurringPaymentsProfile'];

  required = ['apiUrl', 'user', 'pwd', 'signature'];

  paypalUrl = process.env.NODE_ENV === 'production' && 'https://www.paypal.com' || 'https://www.sandbox.paypal.com/';

  defaults = {
    apiUrl: process.env.NODE_ENV === 'production' && 'https://api-3t.paypal.com/nvp' || 'https://api-3t.sandbox.paypal.com/nvp',
    version: '85.0'
  };

  module.exports = paypal = {
    options: Object.create(defaults),
    configure: function(opts) {
      var key, value, _results;
      if (opts == null) opts = {};
      _results = [];
      for (key in opts) {
        value = opts[key];
        _results.push(paypal.options[key] = value);
      }
      return _results;
    },
    reset: function() {
      return paypal.options = Object.create(defaults);
    },
    request: function(method, params, cb) {
      var key, missing, upperCaseRequest, url, value;
      if (typeof params === 'function') {
        cb = params;
        params = {};
      }
      params = _({}).defaults(params, paypal.options, {
        method: method
      });
      missing = (function() {
        var _i, _len, _ref, _results;
        _results = [];
        for (_i = 0, _len = required.length; _i < _len; _i++) {
          key = required[_i];
          if (!((_ref = params[key]) != null ? _ref.trim() : void 0)) {
            _results.push(key);
          }
        }
        return _results;
      })();
      if (missing.length !== 0) {
        return cb(new Error("you must configure paypal with " + (missing.join(', '))));
      }
      paypal.log('log', 'Paypal request', paypal.sterilizeRequestForLogging(params));
      url = params.apiUrl;
      delete params.apiUrl;
      upperCaseRequest = {};
      for (key in params) {
        value = params[key];
        upperCaseRequest[key.toUpperCase()] = value;
      }
      return request.post({
        url: url,
        form: upperCaseRequest
      }, function(err, httpResponse) {
        var key, response, value, _ref;
        if (err != null) return cb(err);
        if (httpResponse.statusCode !== 200) {
          return cb(new Error("Unexpected " + httpResponse.statusCode + " response from POST to " + url));
        }
        response = {};
        _ref = qs.parse(httpResponse.body);
        for (key in _ref) {
          value = _ref[key];
          response[key.toLowerCase()] = value;
        }
        paypal.log(response.ack === 'Success' && 'log' || 'error', "Paypal " + response.ack, response);
        switch (response.ack) {
          case 'Success':
            return cb(null, response);
          case 'SuccessWithWarning':
            return cb(null, response);
          case 'Failure':
          case 'FailureWithWarning':
            return cb(new Error(paypal.buildErrorMessage(response)));
          default:
            return cb(new Error("Unknown paypal ack " + response.ack));
        }
      });
    },
    startPaymentFlow: function(params, cb) {
      var returnUrl;
      params = _.clone(params);
      returnUrl = u.parse(params.returnurl, true);
      returnUrl.query._paypalpayment = 'success';
      params.returnurl = u.format(returnUrl);
      return paypal.request('SetExpressCheckout', params, function(err, response) {
        if (err != null) return cb(err);
        if (!response.token) {
          return cb(new Error("[Paypal ref " + response.correlationid + "] missing expected token"));
        }
        return cb(null, "" + paypalUrl + "webscr?" + (qs.stringify({
          cmd: '_express-checkout',
          useraction: 'commit',
          token: response.token
        })));
      });
    },
    parseLists: function(response) {
      var key, match, result, value, _name, _ref;
      result = [];
      for (key in response) {
        value = response[key];
        if (match = key.match(/^l_(.*)(\d+)$/)) {
          ((_ref = result[_name = parseInt(match[2])]) != null ? _ref : result[_name] = {})[match[1]] = value;
        }
      }
      return result;
    },
    buildErrorMessage: function(response) {
      var errors, item, lists;
      lists = paypal.parseLists(response);
      errors = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = lists.length; _i < _len; _i++) {
          item = lists[_i];
          if (item.errorcode) {
            _results.push("" + item.shortmessage + "(" + item.errorcode + "): " + item.longmessage + (item.severitycode && (" - " + item.severitycode) || ''));
          }
        }
        return _results;
      })();
      return "[Paypal " + response.ack + " ref " + response.correlationid + "] " + (errors.join('; '));
    },
    sterilizeRequestForLogging: function(request) {
      var key, result, value, _ref;
      result = {};
      for (key in request) {
        value = request[key];
        result[key] = ((_ref = key.toLowerCase()) === 'password' || _ref === 'pwd' || _ref === 'passwd' || _ref === 'signature') && '[HIDDEN]' || value;
      }
      return result;
    },
    log: function() {
      var args, level;
      level = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      return console[level].apply(console, args);
    }
  };

  _fn = function(method) {
    return paypal[method[0].toLowerCase() + method.slice(1)] = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return paypal.request.apply(paypal, [method].concat(__slice.call(args)));
    };
  };
  for (_i = 0, _len = API.length; _i < _len; _i++) {
    method = API[_i];
    _fn(method);
  }

}).call(this);
