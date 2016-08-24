

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'MULTIMIX'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
{ join }                  = require 'path'
#...........................................................................................................
σ_new_state               = Symbol.for 'new_state'
σ_reject                  = Symbol.for 'reject'
σ_finalize                = Symbol.for 'finalize'


#-----------------------------------------------------------------------------------------------------------
MULTIMIX          = {}
MULTIMIX.TOOLS    = require './tools'
MULTIMIX.REDUCERS = require './reducers'

#-----------------------------------------------------------------------------------------------------------
MULTIMIX.mix = ( me, reducers, mixins, root = null, selector = [] ) ->
  #.........................................................................................................
  return null unless mixins.length > 0
  ### TAINT support multiple types at all or only PODs? ###
  R     = if CND.isa_list mixins[ 0 ] then [] else {}
  S     = me.REDUCERS[ σ_new_state ] reducers
  root ?= R
  #.........................................................................................................
  ### Deal with nested reducers first: ###
  for rd_key, rd_value of reducers
    if CND.isa_pod rd_value
      selector.push rd_key
      partial_mixins = []
      for mixin in mixins
        partial_mixin = mixin[ rd_key ]
        partial_mixins.push partial_mixin if partial_mixin?
      if partial_mixins.length > 0
        R[ rd_key ] = MULTIMIX.mix me, rd_value, partial_mixins, root, selector
      reducers[ rd_key ]  = 'skip'
      selector.pop rd_key
  #.........................................................................................................
  ### Process unnested reducers: ###
  for mixin in mixins
    for mx_key, mx_value of mixin
      S.path          = join selector..., mx_key
      S.root          = root
      S.current       = R
      S.reducer_name  = S.reducers[ mx_key ] ? S.reducer_fallback
      continue if me.REDUCERS[ σ_reject ] S, mx_key, mx_value
      unless ( reducer = me.REDUCERS[ S.reducer_name ] )?
        throw new Error "unknown reducer #{rpr S.reducer_name}"
      reducer.call me.REDUCERS, S, mx_key, mx_value
  #.........................................................................................................
  me.REDUCERS[ σ_finalize ] S
  #.........................................................................................................
  # S.path    = null
  # S.root    = null
  # S.current = null
  return R

#-----------------------------------------------------------------------------------------------------------
MULTIMIX._copy_object = ( x, seen ) ->
  ### shamelessly copied from https://github.com/nrn/universal-copy ###
  R = Object.create Object.getPrototypeOf x
  seen.set x, R
  if      Object.isFrozen     x then Object.freeze            R
  if      Object.isSealed     x then Object.seal              R
  unless  Object.isExtensible x then Object.preventExtensions R
  return R

#-----------------------------------------------------------------------------------------------------------
MULTIMIX._copy_constructor = ( x, seen ) ->
  ### shamelessly copied from https://github.com/nrn/universal-copy ###
  R = new x.constructor x
  seen.set x, R
  return R

#-----------------------------------------------------------------------------------------------------------
MULTIMIX.use = ( custom_reducers... ) ->
  ### Returns a version of `mix` that uses the reducers passed in to `use`; the resulting reducer is
  derived from the reducers list by applying `mix`. Turtles. ###
  custom_reducers.splice 0, 0, { '*': 'assign', }
  reducers        = MULTIMIX.mix MULTIMIX, null, custom_reducers
  R               = ( mixins... ) -> MULTIMIX.mix R, reducers, mixins
  R.TOOLS         = MULTIMIX.TOOLS
  R.REDUCERS      = MULTIMIX.REDUCERS
  R.use           = MULTIMIX.use
  # R.copy          = ( x ) -> MULTIMIX.copy R, reducers, x
  R.deep_copy     = ( x ) -> CND.deep_copy x
  return R

#-----------------------------------------------------------------------------------------------------------
module.exports = { mix: MULTIMIX.use(), }








