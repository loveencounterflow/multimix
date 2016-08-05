

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
TOOLS                     = require './tools'


#-----------------------------------------------------------------------------------------------------------
module.exports = MMX = {}

#-----------------------------------------------------------------------------------------------------------
MMX.mix = ( mixins... ) ->
  # debug arguments.callee is MMX.mix
  return null unless mixins.length > 0
  # debug '5021', 'mix.reducers', @mix.reducers
  reducer_fallback  = @mix.reducers[ '*' ] ? 'assign'
  exclude           = []
  ### TAINT support multiple types at all or only PODs? ###
  R                 = if CND.isa_list mixins[ 0 ] then [] else {}
  #.........................................................................................................
  for mixin in mixins
    for key, value of mixin
      continue if key in exclude
      reducer = @mix.reducers[ key ] ? reducer_fallback
      #.....................................................................................................
      ### TAINT in e.g. mode `append`, should value be skipped if it is `null`? ###
      switch reducer
        #...................................................................................................
        when 'skip'
          continue
        #...................................................................................................
        when 'assign'
          if value is undefined then delete R[ key ]
          else                              R[ key ] = value
        #...................................................................................................
        when 'append'
          ### TAINT consider to use `Symbol.isConcatSpreadable` in the future ###
          target = ( R[ key ] ?= [] )
          if CND.isa_list then  target.splice target.length, 0, value...
          else                  target.push                     value
        #...................................................................................................
        when 'list'
          ( R[ key ] ?= [] ).push value
        #...................................................................................................
        # when 'add'      then R[ key ]         = ( R[ key ] ? 0 ) + value
        # when 'tag'      then meld ( target = R[ key ] ?= [] ), value
        # when 'function' then ( cache[ key ] ?= [] ).push [ entry[ 'id' ], value, ]
        #...................................................................................................
        else throw new Error "unknown reducer #{rpr reducer}"
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
use = ( reducers... ) ->
  ### Returns a version of mix that uses the reducers passed in to `use`; the resulting reducer is
  derived form the reducers list by applying `mix`. Turtles. ###
  R               = {}
  R.mix           = MMX.mix.bind R
  R.mix.reducers  = MMX.mix MMX.reducers, reducers...
  R.mix.tools     = MMX.mix.tools
  return R.mix

#-----------------------------------------------------------------------------------------------------------
MMX.mix.use = use.bind MMX

#-----------------------------------------------------------------------------------------------------------
MMX.mix.reducers = { '*': 'assign', }

#-----------------------------------------------------------------------------------------------------------
MMX.mix.tools = TOOLS

