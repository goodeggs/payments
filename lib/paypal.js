(function() {
  var defaults, paypal, paypalUrl, qs, request, required,
    __slice = Array.prototype.slice;

  qs = require('querystring');

  request = require('request');

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
      var key, missing, requestParams, settingsObj, upperCaseRequest, url, value, _i, _len, _ref;
      if (typeof params === 'function') {
        cb = params;
        params = {};
      }
      requestParams = {};
      _ref = [
        {
          method: method
        }, paypal.options, params
      ];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        settingsObj = _ref[_i];
        for (key in settingsObj) {
          value = settingsObj[key];
          requestParams[key] = value;
        }
      }
      missing = (function() {
        var _j, _len2, _ref2, _results;
        _results = [];
        for (_j = 0, _len2 = required.length; _j < _len2; _j++) {
          key = required[_j];
          if (!((_ref2 = requestParams[key]) != null ? _ref2.trim() : void 0)) {
            _results.push(key);
          }
        }
        return _results;
      })();
      if (missing.length !== 0) {
        return cb(new Error("you must configure paypal with " + (missing.join(', '))));
      }
      paypal.log('log', 'Paypal request', paypal.sterilizeRequestForLogging(requestParams));
      url = requestParams.apiUrl;
      delete requestParams.apiUrl;
      upperCaseRequest = {};
      for (key in requestParams) {
        value = requestParams[key];
        upperCaseRequest[key.toUpperCase()] = value;
      }
      return request.post({
        url: url,
        form: upperCaseRequest
      }, function(err, httpResponse) {
        var key, response, value, _ref2;
        if (err != null) return cb(err);
        if (httpResponse.statusCode !== 200) {
          return cb(new Error("Unexpected " + httpResponse.statusCode + " response from POST to " + url));
        }
        response = {};
        _ref2 = qs.parse(httpResponse.body);
        for (key in _ref2) {
          value = _ref2[key];
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
    setExpressCheckout: function(params, cb) {
      return paypal.request('SetExpressCheckout', params, function(err, response) {
        if (err != null) return cb(err);
        if (!response.token) {
          return cb(new Error("[Paypal ref " + response.correlationid + "] missing expected token"));
        }
        return cb(null, "" + paypalUrl + "webscr?" + (qs.stringify({
          cmd: '_express-checkout',
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

}).call(this);
