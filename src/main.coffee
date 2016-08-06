

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
  # debug arguments.callee is MULTIMIX.mix
  # debug '5021', 'mix me', me
  # debug '5021', 'mix reducers', reducers
  # debug '5021', 'mix mixins', mixins
  #.........................................................................................................
  return null unless mixins.length > 0
  ### TAINT support multiple types at all or only PODs? ###
  R = if CND.isa_list mixins[ 0 ] then [] else {}
  S = {}
  #.........................................................................................................
  ### TAINT presently the reducers namespace has mixin keys as keys except for the special
  key '*'. This severly restricts the expressiveness of the configuration. Solutions:
  * move mixin keys to a segregated object
  * use sigils like '~' or syntax like '<type>' for special keys
  * reserve one other special key for all special keys
  ###
  S.reducers          = reducers ? {}
  S.reducer_fallback  = S.reducers[ '*' ] ? 'assign'
  #.........................................................................................................
  S.cache             = {}
  S.averages          = {}
  S.tag_keys          = ( key for key, value of S.reducers when value is 'tag' )
  S.skip              = [] # ( key for key in [ 'idx', 'id', 'lo', 'hi', 'size', ] when not ( key of S.reducers ) )
  S.functions         = {}
  #.........................................................................................................
  for key, reducer of S.reducers
    if reducer is 'include'
      S.reducers[ key ] = S.reducer_fallback
      continue
    if CND.isa_function reducer
      S.functions[  key ] = reducer
      S.reducers[   key ] = 'function'
  #.........................................................................................................
  for mixin in mixins
    for key, value of mixin
      continue if ( key in S.skip ) or ( value is undefined and reducer isnt 'assign' )
      reducer = S.reducers[ key ] ? S.reducer_fallback
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
        when 'merge'
          me.REDUCERS.merge S, R, key, value
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
        when 'add'      then R[ key ] = ( R[ key ] ? 0 ) + value
        when 'tag'      then me.tools.meld ( target = R[ key ] ?= [] ), value
        when 'function' then ( S.cache[ key ] ?= [] ).push value
        #...................................................................................................
        else throw new Error "unknown reducer #{rpr reducer}"
  #.........................................................................................................
  ### tags ###
  for key, value of R
    continue unless key in S.tag_keys
    R[ key ] = reduce_tag R[ key ]
  #.........................................................................................................
  ### averages ###
  for key, [ sum, count, ] of S.averages
    R[ key ] = sum / count
  #.........................................................................................................
  ### functions ###
  for key, values of S.cache
    R[ key ] = S.functions[ key ] values, R
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








