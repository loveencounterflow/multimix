(function() {
  'use strict';
  var E, GUY, H, alert, debug, echo, freeze, get, get_types, help, hide, info, inspect, iterator_symbol, log, multimix_symbol, nameit, node_inspect, nosuchvalue, plain, praise, rpr, rvr, stringtag_symbol, truth, urge, warn, whisper;

  //###########################################################################################################
  GUY = require('guy');

  ({alert, debug, help, info, plain, praise, urge, warn, whisper} = GUY.trm.get_loggers('MULTIMIX'));

  ({rpr, inspect, echo, log} = GUY.trm);

  ({get, hide} = GUY.props);

  ({freeze} = GUY.lft);

  rvr = GUY.trm.reverse;

  truth = GUY.trm.truth.bind(GUY.trm);

  node_inspect = Symbol.for('nodejs.util.inspect.custom');

  nameit = function(name, f) {
    return Object.defineProperty(f, 'name', {
      value: name
    });
  };

  H = {};

  E = require('./errors');

  multimix_symbol = Symbol('multimix');

  stringtag_symbol = Symbol.toStringTag;

  iterator_symbol = Symbol.iterator;

  nosuchvalue = Symbol('nosuchvalue');

  //===========================================================================================================
  get_types = function() {
    var Intertype, R, types;
    if ((R = H.types) != null) {
      return R;
    }
    //---------------------------------------------------------------------------------------------------------
    ({Intertype} = require('intertype'));
    types = new Intertype();
    //---------------------------------------------------------------------------------------------------------
    types.declare.hdg_new_hedge_cfg({
      $handler: 'function',
      $hub: 'optional.function.or.object',
      // $state:       'optional.object'
      $create: 'boolean.or.function',
      $strict: 'boolean',
      $oneshot: 'boolean',
      $deletion: 'boolean',
      $hide: 'boolean',
      extras: false,
      default: {
        hub: null,
        handler: null,
        // state:      null
        create: null,
        strict: false,
        oneshot: false,
        deletion: true,
        hide: true
      }
    });
    //---------------------------------------------------------------------------------------------------------
    return types;
  };

  //===========================================================================================================
  this.Multimix = (function() {
    class Multimix {
      //---------------------------------------------------------------------------------------------------------
      constructor(cfg) {
        var R, clasz, descriptor, key, mmx, ref;
        /* TAINT bug in Intertype::create() / Intertype::validate(), returns `true` instead of input value */
        // cfg     = create.hdg_new_hedge_cfg cfg
        //.......................................................................................................
        /* TAINT temporary code to avoid faulty `Intertype::validate` */
        /* NOTE use `create` when `validate` is fixed */
        /* TAINT circular dependency Intertype <--> GUY.props.Hedge ??? */
        mmx = this;
        hide(mmx, 'types', get_types());
        cfg = {...cfg};
        if (cfg.hub == null) {
          cfg.hub = mmx;
        }
        if (cfg.create == null) {
          cfg.create = !cfg.strict;
        }
        cfg = {...mmx.types.isa.hdg_new_hedge_cfg.default, ...cfg};
        clasz = mmx.constructor;
        if (!mmx.types.isa.function(cfg.handler)) {
          throw new E.Multimix_cfg_error('^mmx.ctor@1^', `need handler, got ${rpr(cfg.handler)}`);
        }
        if (!mmx.types.isa.boolean.or.function(cfg.create)) {
          throw new E.Multimix_cfg_error('^mmx.ctor@2^', `expected boolean or function, got ${rpr(cfg.create)}`);
        }
        if (!mmx.types.isa.boolean(cfg.strict)) {
          throw new E.Multimix_cfg_error('^mmx.ctor@3^', `expected boolean, got ${rpr(cfg.strict)}`);
        }
        if (cfg.strict && (cfg.create !== false)) {
          throw new E.Multimix_cfg_error('^mmx.ctor@4^', "cannot set both `create` and `strict`");
        }
        if (!mmx.types.isa.boolean(cfg.oneshot)) {
          throw new E.Multimix_cfg_error('^mmx.ctor@5^', `expected boolean, got ${rpr(cfg.oneshot)}`);
        }
        for (key in mmx.types.isa.hdg_new_hedge_cfg.default) {
          //.......................................................................................................
          mmx[key] = cfg[key];
        }
        //.......................................................................................................
        /* set `mmx.state` to a value shared by all Multimix instances with the same `hub`: */
        (mmx.state = clasz.states.get(mmx.hub));
        if (mmx.state === void 0) {
          clasz.states.set(mmx.hub, mmx.state = structuredClone(clasz.state));
        }
        //.......................................................................................................
        R = mmx._get_proxy(true, mmx, (...P) => {
          return mmx.handler.call(mmx.hub, [], ...P);
        });
        ref = Object.getOwnPropertyDescriptors(this.handler);
        for (key in ref) {
          descriptor = ref[key];
          if (key === 'length') {
            continue;
          }
          if (key === 'prototype') {
            continue;
          }
          Object.defineProperty(R, key, descriptor);
        }
        return R;
      }

      //---------------------------------------------------------------------------------------------------------
      _get_proxy(is_top, mmx, handler) {
        var R, clasz, dsc;
        clasz = this.constructor;
        dsc = {
          //-----------------------------------------------------------------------------------------------------
          get: (target, key) => {
            var R, hedges, proxy;
            // debug '^43453^', { target, key, mmx_hub: mmx.hub, }
            switch (key) {
              case multimix_symbol:
                return mmx;
              case stringtag_symbol:
                return `${target.constructor.name}`;
              case 'constructor':
                return target.constructor;
              case 'toString':
                return target.toString;
              case 'call':
                return target.call;
              case 'apply':
                return target.apply;
              case iterator_symbol:
                return target[Symbol.iterator];
              case node_inspect:
                return target[node_inspect];
              /* NOTE necessitated by behavior of `node:util.inspect()`: */
              case '0':
                return target[0];
            }
            //...................................................................................................
            if (is_top) {
              this.state.hedges = [key];
            } else {
              this.state.hedges.push(key);
            }
            dsc.apply = (target, self, P) => {
              return this.handler.call(self, [...this.state.hedges], ...P);
            };
            if ((R = get(target, key, nosuchvalue)) !== nosuchvalue) {
              //...................................................................................................
              // @handler @state.hedges ### put call for prop access here ###
              return R;
            }
            if (this.strict) {
              throw new E.Multimix_no_such_property('^mmx.proxy.get@1^', key);
            }
            if (this.create === false) {
              return void 0;
            }
            hedges = [...this.state.hedges];
            if (this.create === true) {
              handler = this.handler;
            } else {
              this.create(key, target);
              return target[key];
            }
            //...................................................................................................
            proxy = this._get_proxy(false, mmx, nameit(key, (...P) => {
              R = handler.call(mmx.hub, hedges, ...P);
              this.state.hedges = [];
              return R;
            }));
            if (this.hide) {
              hide(target, key, proxy);
            } else {
              target[key] = proxy;
            }
            return proxy;
          },
          //-----------------------------------------------------------------------------------------------------
          set: (target, key, value) => {
            if (this.oneshot && (get(target, key, nosuchvalue)) !== nosuchvalue) {
              throw new E.Multimix_reassignment_error('^mmx.proxy.set@1^', key);
            }
            return target[key] = value;
          },
          //-----------------------------------------------------------------------------------------------------
          deleteProperty: (target, key) => {
            if (!this.deletion) {
              throw new E.Multimix_deletion_error('^mmx.proxy.set@1^', key);
            }
            return delete target[key];
          }
        };
        //.......................................................................................................
        return R = new Proxy(handler, dsc);
      }

    };

    Multimix.symbol = multimix_symbol;

    Multimix.states = new WeakMap();

    Multimix.state = GUY.lft.freeze({
      hedges: []
    });

    return Multimix;

  }).call(this);

}).call(this);

//# sourceMappingURL=main.js.map