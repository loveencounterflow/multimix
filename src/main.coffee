
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
  whisper }               = GUY.trm.get_loggers 'MULTIMIX'
{ rpr
  inspect
  echo
  log     }               = GUY.trm
{ get
  hide }                  = GUY.props
{ freeze }                = GUY.lft
rvr                       = GUY.trm.reverse
truth                     = GUY.trm.truth.bind GUY.trm
node_inspect              = Symbol.for 'nodejs.util.inspect.custom'
nameit                    = ( name, f ) -> Object.defineProperty f, 'name', { value: name, }
H                         = {}
E                         = require './errors'
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
    $strict:      'boolean'
    $oneshot:     'boolean'
    $deletion:    'boolean'
    extras:       false
    default:
      hub:        null
      handler:    null
      # state:      null
      create:     null
      strict:     false
      oneshot:    false
      deletion:     true

  #---------------------------------------------------------------------------------------------------------
  return types

#===========================================================================================================
class @Multimix

  @symbol:  multimix_symbol
  @states:  new WeakMap()
  @state:   GUY.lft.freeze { hedges: [], }

  #---------------------------------------------------------------------------------------------------------
  constructor: ( cfg ) ->
    ### TAINT bug in Intertype::create() / Intertype::validate(), returns `true` instead of input value ###
    # cfg     = create.hdg_new_hedge_cfg cfg
    #.......................................................................................................
    ### TAINT temporary code to avoid faulty `Intertype::validate` ###
    ### NOTE use `create` when `validate` is fixed ###
    ### TAINT circular dependency Intertype <--> GUY.props.Hedge ??? ###
    hide @, 'types', get_types()
    cfg         = { cfg..., }
    cfg.hub    ?= @
    cfg.create ?= not cfg.strict
    cfg         = { @types.isa.hdg_new_hedge_cfg.default..., cfg..., }
    clasz       = @constructor
    throw new E.Multimix_cfg_error '^mmx.ctor<@1^', "need handler, got #{rpr cfg.handler}" unless @types.isa.function cfg.handler
    throw new E.Multimix_cfg_error '^mmx.ctor<@2^', "expected boolean or function"         unless @types.isa.boolean.or.function cfg.create
    throw new E.Multimix_cfg_error '^mmx.ctor<@3^', "expected boolean"                     unless @types.isa.boolean cfg.strict
    throw new E.Multimix_cfg_error '^mmx.ctor<@4^', "cannot set both `create` and `strict`" if cfg.strict and ( cfg.create isnt false )
    throw new E.Multimix_cfg_error '^mmx.ctor<@5^', "expected boolean"                     unless @types.isa.boolean cfg.oneshot
    #.......................................................................................................
    @[ key ] = cfg[ key ] for key of @types.isa.hdg_new_hedge_cfg.default
    #.......................................................................................................
    ### set `@state` to a value shared by all Multimix instances with the same `hub`: ###
    if ( state = clasz.states.get @hub )? then  @state                        = state
    else                                        clasz.states.set @hub, @state = { clasz.state..., }
    #.......................................................................................................
    return @_get_proxy true, ( P... ) => @handler.call @hub, [], P...

  #---------------------------------------------------------------------------------------------------------
  _get_proxy: ( is_top, handler ) ->
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
        dsc.apply = ( target, self, P ) => @handler.call self, [ @state.hedges..., ], P...
        #...................................................................................................
        # @handler @state.hedges ### put call for prop access here ###
        return R if ( R = get target, key, nosuchvalue ) isnt nosuchvalue
        throw new E.Multimix_no_such_property '^mmx.proxy.get@1^', key if @strict
        return undefined if @create is false
        hedges  = [ @state.hedges..., ]
        if @create is true then handler = @handler
        else @create key, target; return target[ key ]
        #...................................................................................................
        return target[ key ] = @_get_proxy false, nameit key, ( P... ) =>
          ### put code for tracing here ###
          return handler.call @hub, hedges, P...
      #-----------------------------------------------------------------------------------------------------
      set: ( target, key, value ) =>
        if @oneshot and ( get target, key, nosuchvalue ) isnt nosuchvalue
          throw new E.Multimix_reassignment_error '^mmx.proxy.set@1^', key
        return target[ key ] = value
      #-----------------------------------------------------------------------------------------------------
      deleteProperty: ( target, key ) =>
        unless @deletion
          throw new E.Multimix_deletion_error '^mmx.proxy.set@1^', key
        return delete target[ key ]
    #.......................................................................................................
    R = new Proxy handler, dsc


