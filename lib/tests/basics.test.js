(function() {
  'use strict';
  var CND, alert, badge, debug, echo, help, info, log, njs_path, praise, rpr, test, urge, warn, whisper;

  //###########################################################################################################
  // njs_util                  = require 'util'
  njs_path = require('path');

  // njs_fs                    = require 'fs'
  //...........................................................................................................
  CND = require('cnd');

  rpr = CND.rpr.bind(CND);

  badge = 'INTERTYPE/tests/main';

  log = CND.get_logger('plain', badge);

  info = CND.get_logger('info', badge);

  whisper = CND.get_logger('whisper', badge);

  alert = CND.get_logger('alert', badge);

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  praise = CND.get_logger('praise', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  test = require('guy-test');

  //-----------------------------------------------------------------------------------------------------------
  this["classes with MultiMix"] = function(T, done) {
    var A, B, Multimix, a, b;
    Multimix = require('../..');
    //.........................................................................................................
    A = class A {
      method1(x) {
        // urge '^33442^', intertype.all_keys_of @
        return x + 2;
      }

      method2(x) {
        return (this.method1(x)) * 2;
      }

    };
    a = new A();
    T.eq(a.method1(100), 102);
    T.eq(a.method2(100), 204);
    //.........................................................................................................
    B = class B extends Multimix {
      method1(x) {
        // urge '^33442^', intertype.all_keys_of @
        return x + 2;
      }

      method2(x) {
        return (this.method1(x)) * 2;
      }

    };
    b = new B();
    T.eq(b.method1(100), 102);
    T.eq(b.method2(100), 204);
    return done();
  };

}).call(this);
