

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


#-----------------------------------------------------------------------------------------------------------
MULTIMIX          = {}
MULTIMIX.TOOLS    = require './tools'
MULTIMIX.REDUCERS = require './reducers'

#-----------------------------------------------------------------------------------------------------------
MULTIMIX.mix = ( me, reducers, mixins ) ->
  σ_new_state = Symbol.for 'new_state'
  σ_reject    = Symbol.for 'reject'
  σ_finalize  = Symbol.for 'finalize'
  #.........................................................................................................
  return null unless mixins.length > 0
  ### TAINT support multiple types at all or only PODs? ###
  R = if CND.isa_list mixins[ 0 ] then [] else {}
  S = me.REDUCERS[ σ_new_state ] reducers
  #.........................................................................................................
  for mixin in mixins
    for key, value of mixin
      continue if me.REDUCERS[ σ_reject ] S, R, key, value
      reducer_name = S.reducers[ key ] ? S.reducer_fallback
      unless ( reducer = me.REDUCERS[ reducer_name ] )?
        throw new Error "unknown reducer #{rpr reducer_name}"
      reducer.call me.REDUCERS, S, R, key, value
  #.........................................................................................................
  me.REDUCERS[ σ_finalize ] S, R
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
MULTIMIX.use = ( custom_reducers... ) ->
  ### Returns a version of mix that uses the reducers passed in to `use`; the resulting reducer is
  derived form the reducers list by applying `mix`. Turtles. ###
  custom_reducers.splice 0, 0, { '*': 'assign', }
  reducers        = MULTIMIX.mix MULTIMIX, null, custom_reducers
  R               = ( mixins... ) -> MULTIMIX.mix R, reducers, mixins
  R.TOOLS         = MULTIMIX.TOOLS
  R.REDUCERS      = MULTIMIX.REDUCERS
  R.use           = MULTIMIX.use
  return R

#-----------------------------------------------------------------------------------------------------------
module.exports = { mix: MULTIMIX.use(), }








