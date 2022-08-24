
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
{ get }                   = GUY.props
rvr                       = GUY.trm.reverse
truth                     = GUY.trm.truth.bind GUY.trm
node_inspect              = Symbol.for 'nodejs.util.inspect.custom'
nameit                    = ( name, f ) -> Object.defineProperty f, 'name', { value: name, }
H                         = {}
multimix_symbol           = Symbol 'multimix'
stringtag_symbol          = Symbol.toStringTag
iterator_symbol           = Symbol.iterator
nosuchvalue               = Symbol 'nosuchvalue'


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
    # $state:       'optional.object'
    $create:      'boolean.or.function'
    default:
      hub:        null
      handler:    null
      # state:      null
      create:     true

  #---------------------------------------------------------------------------------------------------------
  return types

#===========================================================================================================
class @Multimix

  @symbol:  multimix_symbol
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
    throw new Error "^27-1^ need handler, got #{rpr cfg.handler}"  unless @types.isa.function cfg.handler
    throw new Error "^27-2^ expected boolean or function"          unless @types.isa.boolean.or.function cfg.create
    #.......................................................................................................
    ### set `@state` to a value shared by all Multimix instances with the same `hub`: ###
    @hub = cfg.hub ? @
    if ( state = clasz.states.get @hub )? then  @state                        = state
    else                                        clasz.states.set @hub, @state = { clasz.states..., }
    #.......................................................................................................
    @handler      = cfg.handler # .bind @hub
    @create       = cfg.create
    R             = @_get_hedge_proxy true, @handler
    return R

  #---------------------------------------------------------------------------------------------------------
  _get_hedge_proxy: ( is_top, handler ) ->
    clasz = @constructor
    dsc   =
      #-----------------------------------------------------------------------------------------------------
      get: ( target, key ) =>
        switch key
          when  multimix_symbol     then return @
          when  stringtag_symbol    then return "#{target.constructor.name}"
          when  'constructor'       then return target.constructor
          when  'toString'          then return target.toString
          when  'call'              then return target.call
          when  'apply'             then return target.apply
          when  iterator_symbol     then return target[ Symbol.iterator  ]
          when  node_inspect        then return target[ node_inspect     ]
          ### NOTE necessitated by behavior of `node:util.inspect()`: ###
          when  '0'                 then return target[ 0                ]
        #...................................................................................................
        if is_top then  @state.hedges = [ key, ]
        else            @state.hedges.push key
        #...................................................................................................
        # @handler @state.hedges ### put call for prop access here ###
        return R if ( R = get target, key, nosuchvalue ) isnt nosuchvalue
        return undefined if @create is false
        hedges  = [ @state.hedges..., ]
        handler = if @create is true then @handler else @create key, target
        #...................................................................................................
        return target[ key ] = @_get_hedge_proxy false, nameit key, ( P... ) =>
          ### put code for tracing here ###
          return handler.call @hub, hedges, P...
    #.......................................................................................................
    R = new Proxy handler, dsc


