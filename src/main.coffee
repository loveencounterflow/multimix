

### NOTE this code moved to MultiMix ###


###


* class `Hedge`
  * purpose: enable turning property access to function calls
    * propoerties may be predefined
    * or auto-generated, either
      * as plain objects
      * or by calling a custom factory function
    * example:

      ```coffee
      handler = ( hedges, a, b, c ) ->
        log hedges, [ a, b, c, ]
        return null
      h = new Hedge { handler, }
      h.foo
      # [ 'foo',  ]
      ```

* since hubs and properties are proxies, can do things on property access, no call needed, so both `d.foo`
  and `d.foo 42` can potentially do things

* 'handler': function to be called on prop access, call, or both

* 'hub': optional reference / base object (re 'hub': as if props were spokes)


* `cfg`:

  * `cfg.create`: ??????????????????
    * `true`: missing props will be auto-generated as plain objects
    * `true`: no missing props will be generated
    * a function: to be called, return value becomes new property where property is missing


###

############################################################################################################
GUY                       = require '../../../apps/guy'
{ alert
  debug
  help
  info
  plain
  praise
  urge
  warn
  whisper }               = GUY.trm.get_loggers 'GUY/demo-guy-hedgerows'
{ rpr
  inspect
  echo
  log     }               = GUY.trm
rvr                       = GUY.trm.reverse
truth                     = GUY.trm.truth.bind GUY.trm
{ Intertype }             = require '../../../apps/intertype'
types                     = new Intertype()
{ declare
  create
  isa
  validate  }             = types
node_inspect              = Symbol.for 'nodejs.util.inspect.custom'
nameit                    = ( name, f ) -> Object.defineProperty f, 'name', { value: name, }


#-----------------------------------------------------------------------------------------------------------
declare.hdg_new_hedge_cfg
  $handler:     'function'
  $hub:         'optional.function.or.object'
  $state:       'optional.object'
  default:
    hub:        null
    handler:    null
    state:      null


#-----------------------------------------------------------------------------------------------------------
class Hedge

  #---------------------------------------------------------------------------------------------------------
  constructor: ( cfg ) ->
    ### TAINT bug in Intertype::create() / Intertype::validate(), returns `true` instead of input value ###
    # cfg     = create.hdg_new_hedge_cfg cfg
    # urge '^345^', rvr cfg
    #.......................................................................................................
    ### TAINT temporary code to avoid faulty `Intertype::validate` ###
    ### NOTE use `create` when `validate` is fixed ###
    ### TAINT circular dependency Intertype <--> GUY.props.Hedge ??? ###
    cfg       = { isa.hdg_new_hedge_cfg.default..., cfg..., }
    throw new Error "^343^ need handler, got #{rpr cfg.handler}" unless isa.function cfg.handler
    #.......................................................................................................
    @hub      = cfg.hub ? null
    @handler  = cfg.handler # .bind @hub
    @state    = cfg.state ? { hedges: null, }
    R         = @_get_hedge_proxy true, @handler
    return R

  #---------------------------------------------------------------------------------------------------------
  _get_hedge_proxy: ( is_top, handler ) ->
    dsc =
      #-----------------------------------------------------------------------------------------------------
      get: ( target, key ) =>
        return "#{target.constructor.name}"   if key is Symbol.toStringTag
        return target.constructor             if key is 'constructor'
        return target.toString                if key is 'toString'
        return target.call                    if key is 'call'
        return target.apply                   if key is 'apply'
        return target[ Symbol.iterator  ]     if key is Symbol.iterator
        return target[ node_inspect     ]     if key is node_inspect
        ### NOTE necessitated by behavior of `node:util.inspect()`: ###
        return target[ 0                ]     if key is '0'
        # whisper '^450-1^', { target, key, }
        #...................................................................................................
        if is_top then  @state.hedges = [ key, ]
        else            @state.hedges.push key
        #...................................................................................................
        ### put call for prop access here: ###
        # @handler @state.hedges
        return R if ( R = target[ key ] ) isnt undefined
        hedges        = [ @state.hedges..., ]
        #...................................................................................................
        sub_handler = nameit key, ( P... ) =>
          whisper '^450-2^', "call with", { hedges, P, }
          return @handler hedges, P...
        return target[ key ] ?= @_get_hedge_proxy false, sub_handler
    #.......................................................................................................
    R = new Proxy handler, dsc


############################################################################################################
if module is require.main then do =>

  #=========================================================================================================
  paragons =

    #-------------------------------------------------------------------------------------------------------
    isa: ( hedges, x ) ->
      # if arguments.length < 2
      #   debug '^450-3^', "`isa()` called with no argument; leaving"
      #   return null
      unless ( arity = arguments.length ) is 2
        throw new Error "^387^ expected single argument, got #{arity - 1}"
      ### TAINT very much simplified version of `Intertype::_inner_isa()` ###
      # return isa[ hedge ] x
      whisper '^450-4^', { hedges, x, }
      for hedge in hedges
        R = @isa[ hedge ] is false
        whisper '^450-5^', { R, hedge, handler: @isa[ hedge ], x, }
        return false if R is false
        return R unless R is true
      return true

    #-------------------------------------------------------------------------------------------------------
    declare: ( hedges, isa ) ->
      # if arguments.length < 2
      #   debug '^450-6^', "`declare()` called with no argument; leaving"
      #   return null
      # unless ( arity = arguments.length ) is 1
      #   throw new Error "^387^ expected no arguments, got #{arity - 1}"
      ### TAINT also check for hedges being a list ###
      unless ( hedgecount = hedges.length ) is 1
        throw new Error "^387^ expected single hedge, got #{rpr hedges}"
      [ name, ] = hedges
      ### NOTE here chance to add tracing ###
      handler = ( x ) => isa.call @, x
      @isa[ name ] = nameit name, new Hedge { state: @state, hub: @, handler, }
      return true

  #=========================================================================================================
  class Intertype

    #-------------------------------------------------------------------------------------------------------
    constructor: ( cfg ) ->
      # GUY_props.hide @, 'isa', new Hedge
      @state    = { hedges: null, }
      @isa      = nameit 'isa',     new Hedge { state: @state, hub: @, handler: ( paragons.isa.bind      @ ), }
      @declare  = nameit 'declare', new Hedge { state: @state, hub: @, handler: ( paragons.declare.bind  @ ), }
      # debug '^450-10^', rvr @
      return undefined

  #=========================================================================================================
  do =>
    handler = ( hedges, P... ) -> [ hedges..., P..., ]
    hub = new Hedge { handler, }
    info '^450-24^', hub.one.two.three.four.five 5
    return null
  #=========================================================================================================
  do =>
    types = new Intertype()
    info '^450-25^', types
    info '^450-26^', types.isa
    info '^450-27^', types.declare
    info '^450-28^', types.declare.one
    info '^450-29^', types.declare.one ( x ) -> ( x is 1 ) or ( x is '1' )
    info '^450-31^', types.isa.one 1
    info '^450-32^', types.isa.one '1'
    info '^450-33^', types.isa.one 2
    return null
  #---------------------------------------------------------------------------------------------------------
  return null
