
'use strict'


############################################################################################################
GUY                       = require 'guy'
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
node_inspect              = Symbol.for 'nodejs.util.inspect.custom'
nameit                    = ( name, f ) -> Object.defineProperty f, 'name', { value: name, }
H                         = {}

#===========================================================================================================
get_types = ->
  return R if ( R = H.types )?

  #---------------------------------------------------------------------------------------------------------
  { Intertype }             = require 'intertype'
  types                     = new Intertype()

  #---------------------------------------------------------------------------------------------------------
  types.declare.hdg_new_hedge_cfg
    $handler:     'function'
    $hub:         'optional.function.or.object'
    $state:       'optional.object'
    default:
      hub:        null
      handler:    null
      state:      null

  #---------------------------------------------------------------------------------------------------------
  return types

#===========================================================================================================
class @Multimix

  @symbol:  Symbol 'multimix'
  @states:  new WeakMap()
  @state:   GUY.lft.freeze { hedges: null, }

  #---------------------------------------------------------------------------------------------------------
  constructor: ( cfg ) ->
    ### TAINT bug in Intertype::create() / Intertype::validate(), returns `true` instead of input value ###
    # cfg     = create.hdg_new_hedge_cfg cfg
    # urge '^345^', rvr cfg
    #.......................................................................................................
    ### TAINT temporary code to avoid faulty `Intertype::validate` ###
    ### NOTE use `create` when `validate` is fixed ###
    ### TAINT circular dependency Intertype <--> GUY.props.Hedge ??? ###
    @types    = get_types()
    cfg       = { @types.isa.hdg_new_hedge_cfg.default..., cfg..., }
    clasz     = @constructor
    throw new Error "^343^ need handler, got #{rpr cfg.handler}" unless @types.isa.function cfg.handler
    #.......................................................................................................
    ### set `@state` to a value shared by all Multimix instances with the same `hub`: ###
    if cfg.hub?
      @hub      = cfg.hub
      if ( state = clasz.states.get @hub )? then  @state                        = state
      else                                        clasz.states.set @hub, @state = { clasz.states..., }
    else
      @state = { clasz.states..., }
    #.......................................................................................................
    @handler  = cfg.handler # .bind @hub
    # @state    = cfg.state ? { hedges: null, }
    R         = @_get_hedge_proxy true, @handler
    return R

  #---------------------------------------------------------------------------------------------------------
  _get_hedge_proxy: ( is_top, handler ) ->
    clasz = @constructor
    dsc   =
      #-----------------------------------------------------------------------------------------------------
      get: ( target, key ) =>
        switch key
          when  clasz.symbol        then return @
          when  Symbol.toStringTag  then return "#{target.constructor.name}"
          when  'constructor'       then return target.constructor
          when  'toString'          then return target.toString
          when  'call'              then return target.call
          when  'apply'             then return target.apply
          when  Symbol.iterator     then return target[ Symbol.iterator  ]
          when  node_inspect        then return target[ node_inspect     ]
          ### NOTE necessitated by behavior of `node:util.inspect()`: ###
          when  '0'                 then return target[ 0                ]
        #...................................................................................................
        if is_top then  @state.hedges = [ key, ]
        else            @state.hedges.push key
        #...................................................................................................
        # @handler @state.hedges ### put call for prop access here ###
        return R if ( R = target[ key ] ) isnt undefined
        hedges = [ @state.hedges..., ]
        #...................................................................................................
        sub_handler = nameit key, ( P... ) =>
          whisper '^450-2^', "call with", { hedges, P, }
          return @handler hedges, P...
        return target[ key ] ?= @_get_hedge_proxy false, sub_handler
    #.......................................................................................................
    R = new Proxy handler, dsc


