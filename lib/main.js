(function() {
  'use strict';
  var GUY, H, alert, debug, echo, get_types, help, info, inspect, log, nameit, node_inspect, plain, praise, rpr, rvr, truth, urge, warn, whisper;

  //###########################################################################################################
  GUY = require('guy');

  ({alert, debug, help, info, plain, praise, urge, warn, whisper} = GUY.trm.get_loggers('GUY/demo-guy-hedgerows'));

  ({rpr, inspect, echo, log} = GUY.trm);

  rvr = GUY.trm.reverse;

  truth = GUY.trm.truth.bind(GUY.trm);

  node_inspect = Symbol.for('nodejs.util.inspect.custom');

  nameit = function(name, f) {
    return Object.defineProperty(f, 'name', {
      value: name
    });
  };

  H = {};

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
      $state: 'optional.object',
      default: {
        hub: null,
        handler: null,
        state: null
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
        var R, clasz, state;
        /* TAINT bug in Intertype::create() / Intertype::validate(), returns `true` instead of input value */
        // cfg     = create.hdg_new_hedge_cfg cfg
        // urge '^345^', rvr cfg
        //.......................................................................................................
        /* TAINT temporary code to avoid faulty `Intertype::validate` */
        /* NOTE use `create` when `validate` is fixed */
        /* TAINT circular dependency Intertype <--> GUY.props.Hedge ??? */
        this.types = get_types();
        cfg = {...this.types.isa.hdg_new_hedge_cfg.default, ...cfg};
        clasz = this.constructor;
        if (!this.types.isa.function(cfg.handler)) {
          throw new Error(`^343^ need handler, got ${rpr(cfg.handler)}`);
        }
        //.......................................................................................................
        /* set `@state` to a value shared by all Multimix instances with the same `hub`: */
        if (cfg.hub != null) {
          this.hub = cfg.hub;
          if ((state = clasz.states.get(this.hub)) != null) {
            this.state = state;
          } else {
            clasz.states.set(this.hub, this.state = {...clasz.states});
          }
        } else {
          this.state = {...clasz.states};
        }
        //.......................................................................................................
        this.handler = cfg.handler; // .bind @hub
        // @state    = cfg.state ? { hedges: null, }
        R = this._get_hedge_proxy(true, this.handler);
        return R;
      }

      //---------------------------------------------------------------------------------------------------------
      _get_hedge_proxy(is_top, handler) {
        var R, clasz, dsc;
        clasz = this.constructor;
        dsc = {
          //-----------------------------------------------------------------------------------------------------
          get: (target, key) => {
            var R, hedges, sub_handler;
            switch (key) {
              case clasz.symbol:
                return this;
              case Symbol.toStringTag:
                return `${target.constructor.name}`;
              case 'constructor':
                return target.constructor;
              case 'toString':
                return target.toString;
              case 'call':
                return target.call;
              case 'apply':
                return target.apply;
              case Symbol.iterator:
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
            if ((R = target[key]) !== void 0) {
              //...................................................................................................
              // @handler @state.hedges ### put call for prop access here ###
              return R;
            }
            hedges = [...this.state.hedges];
            //...................................................................................................
            sub_handler = nameit(key, (...P) => {
              whisper('^450-2^', "call with", {hedges, P});
              return this.handler(hedges, ...P);
            });
            return target[key] != null ? target[key] : target[key] = this._get_hedge_proxy(false, sub_handler);
          }
        };
        //.......................................................................................................
        return R = new Proxy(handler, dsc);
      }

    };

    Multimix.symbol = Symbol('multimix');

    Multimix.states = new WeakMap();

    Multimix.state = GUY.lft.freeze({
      hedges: null
    });

    return Multimix;

  }).call(this);

}).call(this);

//# sourceMappingURL=main.js.map