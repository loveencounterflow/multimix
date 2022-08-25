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
      extras: false,
      default: {
        hub: null,
        handler: null,
        // state:      null
        create: null,
        strict: false,
        oneshot: false,
        deletion: true
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
        var clasz, key, state;
        /* TAINT bug in Intertype::create() / Intertype::validate(), returns `true` instead of input value */
        // cfg     = create.hdg_new_hedge_cfg cfg
        //.......................................................................................................
        /* TAINT temporary code to avoid faulty `Intertype::validate` */
        /* NOTE use `create` when `validate` is fixed */
        /* TAINT circular dependency Intertype <--> GUY.props.Hedge ??? */
        hide(this, 'types', get_types());
        cfg = {...cfg};
        if (cfg.hub == null) {
          cfg.hub = this;
        }
        if (cfg.create == null) {
          cfg.create = !cfg.strict;
        }
        cfg = {...this.types.isa.hdg_new_hedge_cfg.default, ...cfg};
        clasz = this.constructor;
        if (!this.types.isa.function(cfg.handler)) {
          throw new E.Multimix_cfg_error('^mmx.ctor<@1^', `need handler, got ${rpr(cfg.handler)}`);
        }
        if (!this.types.isa.boolean.or.function(cfg.create)) {
          throw new E.Multimix_cfg_error('^mmx.ctor<@2^', "expected boolean or function");
        }
        if (!this.types.isa.boolean(cfg.strict)) {
          throw new E.Multimix_cfg_error('^mmx.ctor<@3^', "expected boolean");
        }
        if (cfg.strict && (cfg.create !== false)) {
          throw new E.Multimix_cfg_error('^mmx.ctor<@4^', "cannot set both `create` and `strict`");
        }
        if (!this.types.isa.boolean(cfg.oneshot)) {
          throw new E.Multimix_cfg_error('^mmx.ctor<@5^', "expected boolean");
        }
        for (key in this.types.isa.hdg_new_hedge_cfg.default) {
          //.......................................................................................................
          this[key] = cfg[key];
        }
        //.......................................................................................................
        /* set `@state` to a value shared by all Multimix instances with the same `hub`: */
        if ((state = clasz.states.get(this.hub)) != null) {
          this.state = state;
        } else {
          clasz.states.set(this.hub, this.state = {...clasz.state});
        }
        //.......................................................................................................
        return this._get_proxy(true, (...P) => {
          return this.handler.call(this.hub, [], ...P);
        });
      }

      //---------------------------------------------------------------------------------------------------------
      _get_proxy(is_top, handler) {
        var R, clasz, dsc;
        clasz = this.constructor;
        dsc = {
          //-----------------------------------------------------------------------------------------------------
          get: (target, key) => {
            var R, hedges;
            switch (key) {
              case multimix_symbol:
                return this;
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
              dsc.apply = (target, self, P) => {
                return this.handler.call(self, [key], ...P);
              };
            } else {
              this.state.hedges.push(key);
              dsc.apply = (target, self, P) => {
                return this.handler.call(self, [...this.state.hedges], ...P);
              };
            }
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
            return target[key] = this._get_proxy(false, nameit(key, (...P) => {
              R = handler.call(this.hub, hedges, ...P);
              this.state.hedges = [];
              return R;
            }));
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