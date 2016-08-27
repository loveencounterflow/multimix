

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
σ_unknown_type            = Symbol.for 'unknown_type'
#...........................................................................................................
MULTIMIX                  = {}
MULTIMIX.TOOLS            = require './tools'
MULTIMIX.REDUCERS         = require './reducers'
MULTIMIX.COPIERS          = require './copiers'

#-----------------------------------------------------------------------------------------------------------
MULTIMIX._get_seed = ( L, S, seed ) ->
  type          = CND.type_of seed
  description   = L.type_descriptions[ type ] ? L.type_descriptions[ σ_unknown_type ]
  { has_fields
    copy      } = description
  return copy.call L, S, seed

#-----------------------------------------------------------------------------------------------------------
MULTIMIX.mix = ( L, mixins, reducers, root = null, selector = [] ) ->
  #.........................................................................................................
  return null if mixins.length is 0
  [ mixin_seed
    mixin_tail... ]   = mixins
  S                   = L.REDUCERS[ σ_new_state ] reducers, mixins
  seed                = MULTIMIX._get_seed L, S, mixin_seed
  S.seed              = seed
  root               ?= seed
  # ### !!! experimental !!! ###
  # for mixin, mixin_idx in mixins
  #   mixins[ mixin_idx ] = { '': mixin, }
  #.........................................................................................................
  ### Deal with nested reducers first: ###
  if ( fields = S.reducers[ 'fields' ] )?
    for field_key, field_value of fields
      if CND.isa_pod field_value
        selector.push field_key
        partial_mixins = []
        for mixin in mixins
          partial_mixin = mixin[ field_key ]
          partial_mixins.push partial_mixin if partial_mixin?
        if partial_mixins.length > 0
          S.seed[ field_key ] = MULTIMIX.mix L, partial_mixins, field_value, root, selector
        reducers[ field_key ]  = 'skip'
        selector.pop field_key
  #.........................................................................................................
  ### Process unnested reducers: ###
  for mixin in mixins
    urge '33415', mixin
    for mx_key, mx_value of mixin
      S.path          = join selector..., mx_key
      S.root          = root
      S.current       = S.seed
      S.reducer_name  = S.reducers[ 'fields' ]?[ mx_key ] ? S.reducer_fallback
      continue if L.REDUCERS[ σ_reject ] S, mx_key, mx_value
      unless ( reducer = L.REDUCERS[ S.reducer_name ] )?
        throw new Error "unknown reducer #{rpr S.reducer_name}"
      reducer.call L.REDUCERS, S, mx_key, mx_value
  #.........................................................................................................
  L.REDUCERS[ σ_finalize ] S
  #.........................................................................................................
  if ( hook = S.reducers?[ 'after' ] )?
    unless ( type = CND.type_of hook ) is 'function'
      throw new Error "expected function for 'after' hook, got a #{type}"
    hook S
  #.........................................................................................................
  # S.path    = null
  # S.root    = null
  # S.current = null
  debug '30221', S
  return S.seed



#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
MULTIMIX.use = ( custom_reducers... ) ->
  ### Returns a version of `mix` that uses the reducers passed in to `use`; the resulting reducer is
  derived from the reducers list by applying `mix`. Turtles. ###
  custom_reducers.splice 0, 0, { '*': 'assign', }
  reducers            = MULTIMIX.mix MULTIMIX, custom_reducers, null
  # debug '28773', custom_reducers
  # urge '28773', reducers
  R                   = ( mixins... ) -> MULTIMIX.mix R, mixins, reducers
  R.TOOLS             = MULTIMIX.TOOLS
  R.REDUCERS          = MULTIMIX.REDUCERS
  R.COPIERS           = MULTIMIX.COPIERS
  R.type_descriptions = MULTIMIX.type_descriptions
  R._get_seed         = MULTIMIX._get_seed
  R.use               = MULTIMIX.use
  # R.deep_copy         = ( x ) -> CND.deep_copy x
  return R

#-----------------------------------------------------------------------------------------------------------
# module.exports = { mix: MULTIMIX.use(), }








