(function() {
  //###########################################################################################################
  var GUY, Hedge, Intertype, alert, create, debug, declare, echo, help, info, inspect, isa, log, nameit, node_inspect, plain, praise, rpr, rvr, truth, types, urge, validate, warn, whisper;

  GUY = require('guy');

  ({alert, debug, help, info, plain, praise, urge, warn, whisper} = GUY.trm.get_loggers('GUY/demo-guy-hedgerows'));

  ({rpr, inspect, echo, log} = GUY.trm);

  rvr = GUY.trm.reverse;

  truth = GUY.trm.truth.bind(GUY.trm);

  ({Intertype} = require('intertype'));

  types = new Intertype();

  ({declare, create, isa, validate} = types);

  node_inspect = Symbol.for('nodejs.util.inspect.custom');

  nameit = function(name, f) {
    return Object.defineProperty(f, 'name', {
      value: name
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  declare.hdg_new_hedge_cfg({
    $handler: 'function',
    $hub: 'optional.function.or.object',
    $state: 'optional.object',
    default: {
      hub: null,
      handler: null,
      state: null
    }
  });

  //-----------------------------------------------------------------------------------------------------------
  Hedge = class Hedge {
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
      cfg = {...isa.hdg_new_hedge_cfg.default, ...cfg};
      if (!isa.function(cfg.handler)) {
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

  //###########################################################################################################
  if (module === require.main) {
    (() => {
      var paragons;
      //=========================================================================================================
      paragons = {
        //-------------------------------------------------------------------------------------------------------
        isa: function(hedges, x) {
          var R, arity, hedge, i, len;
          // if arguments.length < 2
          //   debug '^450-3^', "`isa()` called with no argument; leaving"
          //   return null
          if ((arity = arguments.length) !== 2) {
            throw new Error(`^387^ expected single argument, got ${arity - 1}`);
          }
          /* TAINT very much simplified version of `Intertype::_inner_isa()` */
          // return isa[ hedge ] x
          whisper('^450-4^', {hedges, x});
          for (i = 0, len = hedges.length; i < len; i++) {
            hedge = hedges[i];
            R = this.isa[hedge] === false;
            whisper('^450-5^', {
              R,
              hedge,
              handler: this.isa[hedge],
              x
            });
            if (R === false) {
              return false;
            }
            if (R !== true) {
              return R;
            }
          }
          return true;
        },
        //-------------------------------------------------------------------------------------------------------
        declare: function(hedges, isa) {
          /* NOTE here chance to add tracing */
          var handler, hedgecount, name;
          // if arguments.length < 2
          //   debug '^450-6^', "`declare()` called with no argument; leaving"
          //   return null
          // unless ( arity = arguments.length ) is 1
          //   throw new Error "^387^ expected no arguments, got #{arity - 1}"
          /* TAINT also check for hedges being a list */
          if ((hedgecount = hedges.length) !== 1) {
            throw new Error(`^387^ expected single hedge, got ${rpr(hedges)}`);
          }
          [name] = hedges;
          handler = (x) => {
            return isa.call(this, x);
          };
          this.isa[name] = nameit(name, new Hedge({
            state: this.state,
            hub: this,
            handler
          }));
          return true;
        }
      };
      //=========================================================================================================
      Intertype = class Intertype {
        //-------------------------------------------------------------------------------------------------------
        constructor(cfg) {
          // GUY_props.hide @, 'isa', new Hedge
          this.state = {
            hedges: null
          };
          this.isa = nameit('isa', new Hedge({
            state: this.state,
            hub: this,
            handler: paragons.isa.bind(this)
          }));
          this.declare = nameit('declare', new Hedge({
            state: this.state,
            hub: this,
            handler: paragons.declare.bind(this)
          }));
          // debug '^450-10^', rvr @
          return void 0;
        }

      };
      (() => {        //=========================================================================================================
        var handler, hub;
        handler = function(hedges, ...P) {
          return [...hedges, ...P];
        };
        hub = new Hedge({handler});
        info('^450-24^', hub.one.two.three.four.five(5));
        return null;
      })();
      (() => {        //=========================================================================================================
        types = new Intertype();
        info('^450-25^', types);
        info('^450-26^', types.isa);
        info('^450-27^', types.declare);
        info('^450-28^', types.declare.one);
        info('^450-29^', types.declare.one(function(x) {
          return (x === 1) || (x === '1');
        }));
        info('^450-31^', types.isa.one(1));
        info('^450-32^', types.isa.one('1'));
        info('^450-33^', types.isa.one(2));
        return null;
      })();
      //---------------------------------------------------------------------------------------------------------
      return null;
    })();
  }

}).call(this);

//# sourceMappingURL=main.js.map