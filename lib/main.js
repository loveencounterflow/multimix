(function() {
  'use strict';
  var GUY, H, alert, debug, echo, get, get_types, help, info, inspect, iterator_symbol, log, multimix_symbol, nameit, node_inspect, nosuchvalue, plain, praise, rpr, rvr, stringtag_symbol, truth, urge, warn, whisper;

  //###########################################################################################################
  GUY = require('guy');

  ({alert, debug, help, info, plain, praise, urge, warn, whisper} = GUY.trm.get_loggers('GUY/demo-guy-hedgerows'));

  ({rpr, inspect, echo, log} = GUY.trm);

  ({get} = GUY.props);

  rvr = GUY.trm.reverse;

  truth = GUY.trm.truth.bind(GUY.trm);

  node_inspect = Symbol.for('nodejs.util.inspect.custom');

  nameit = function(name, f) {
    return Object.defineProperty(f, 'name', {
      value: name
    });
  };

  H = {};

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
      default: {
        hub: null,
        handler: null,
        // state:      null
        create: true
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
        var R, clasz, ref, state;
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
          throw new Error(`^27-1^ need handler, got ${rpr(cfg.handler)}`);
        }
        if (!this.types.isa.boolean.or.function(cfg.create)) {
          throw new Error("^27-2^ expected boolean or function");
        }
        //.......................................................................................................
        /* set `@state` to a value shared by all Multimix instances with the same `hub`: */
        this.hub = (ref = cfg.hub) != null ? ref : this;
        if ((state = clasz.states.get(this.hub)) != null) {
          this.state = state;
        } else {
          clasz.states.set(this.hub, this.state = {...clasz.states});
        }
        //.......................................................................................................
        this.handler = cfg.handler; // .bind @hub
        this.create = cfg.create;
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
            } else {
              this.state.hedges.push(key);
            }
            if ((R = get(target, key, nosuchvalue)) !== nosuchvalue) {
              //...................................................................................................
              // @handler @state.hedges ### put call for prop access here ###
              return R;
            }
            if (this.create === false) {
              return void 0;
            }
            hedges = [...this.state.hedges];
            handler = this.create === true ? this.handler : this.create(key, target);
            //...................................................................................................
            return target[key] = this._get_hedge_proxy(false, nameit(key, (...P) => {
              /* put code for tracing here */
              return handler.call(this.hub, hedges, ...P);
            }));
          }
        };
        //.......................................................................................................
        return R = new Proxy(handler, dsc);
      }

    };

    Multimix.symbol = multimix_symbol;

    Multimix.states = new WeakMap();

    Multimix.state = GUY.lft.freeze({
      hedges: null
    });

    return Multimix;

  }).call(this);

}).call(this);

//# sourceMappingURL=main.js.map