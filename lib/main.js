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
  this.Multimix = class Multimix {
    //---------------------------------------------------------------------------------------------------------
    constructor(cfg) {
      var R, ref, ref1;
      /* TAINT bug in Intertype::create() / Intertype::validate(), returns `true` instead of input value */
      // cfg     = create.hdg_new_hedge_cfg cfg
      // urge '^345^', rvr cfg
      //.......................................................................................................
      /* TAINT temporary code to avoid faulty `Intertype::validate` */
      /* NOTE use `create` when `validate` is fixed */
      /* TAINT circular dependency Intertype <--> GUY.props.Hedge ??? */
      this.types = get_types();
      cfg = {...this.types.isa.hdg_new_hedge_cfg.default, ...cfg};
      if (!this.types.isa.function(cfg.handler)) {
        throw new Error(`^343^ need handler, got ${rpr(cfg.handler)}`);
      }
      //.......................................................................................................
      this.hub = (ref = cfg.hub) != null ? ref : null;
      this.handler = cfg.handler; // .bind @hub
      this.state = (ref1 = cfg.state) != null ? ref1 : {
        hedges: null
      };
      R = this._get_hedge_proxy(true, this.handler);
      return R;
    }

    //---------------------------------------------------------------------------------------------------------
    _get_hedge_proxy(is_top, handler) {
      var R, dsc;
      dsc = {
        //-----------------------------------------------------------------------------------------------------
        get: (target, key) => {
          var R, hedges, sub_handler;
          if (key === Symbol.toStringTag) {
            return `${target.constructor.name}`;
          }
          if (key === 'constructor') {
            return target.constructor;
          }
          if (key === 'toString') {
            return target.toString;
          }
          if (key === 'call') {
            return target.call;
          }
          if (key === 'apply') {
            return target.apply;
          }
          if (key === Symbol.iterator) {
            return target[Symbol.iterator];
          }
          if (key === node_inspect) {
            return target[node_inspect];
          }
          if (key === '0') {
            /* NOTE necessitated by behavior of `node:util.inspect()`: */
            return target[0];
          }
          // whisper '^450-1^', { target, key, }
          //...................................................................................................
          if (is_top) {
            this.state.hedges = [key];
          } else {
            this.state.hedges.push(key);
          }
          if ((R = target[key]) !== void 0) {
            //...................................................................................................
            /* put call for prop access here: */
            // @handler @state.hedges
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

}).call(this);

//# sourceMappingURL=main.js.map