

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
MULTIMIX        = {}
MULTIMIX.TOOLS  = require './tools'

#-----------------------------------------------------------------------------------------------------------
MULTIMIX.mix = ( me, reducers, mixins ) ->
  # debug arguments.callee is MULTIMIX.mix
  # debug '5021', 'mix me', me
  # debug '5021', 'mix reducers', reducers
  # debug '5021', 'mix mixins', mixins
  #.........................................................................................................
  return null unless mixins.length > 0
  ### TAINT support multiple types at all or only PODs? ###
  R                 = if CND.isa_list mixins[ 0 ] then [] else {}
  #.........................................................................................................
  ### TAINT presently the reducers namespace has mixin keys as keys except for the special
  key '*'. This severly restricts the expressiveness of the configuration. Solutions:
  * move mixin keys to a segregated object
  * use sigils like '~' or syntax like '<type>' for special keys
  * reserve one other special key for all special keys
  ###
  reducers         ?= {}
  reducer_fallback  = reducers[ '*' ] ? 'assign'
  exclude           = []
  #.........................................................................................................
  cache             = {}
  averages          = {}
  # reducers          = Object.assign {}, reducers, me[ 'reducers' ] ? {}
  tag_keys          = ( key for key, value of reducers when value is 'tag' )
  exclude           = [] # ( key for key in [ 'idx', 'id', 'lo', 'hi', 'size', ] when not ( key of reducers ) )
  # reducer_fallback  = reducers[ '*' ] ? 'assign'
  functions         = {}
  #.........................................................................................................
  for key, reducer of reducers
    if reducer is 'include'
      reducers[ key ] = reducer_fallback
      continue
    if CND.isa_function reducer
      functions[ key ]  = reducer
      reducers[ key ]   = 'function'
  # #.........................................................................................................
  # unless ( 'tag' in exclude ) or ( 'tag' of reducers )
  #   tag_keys.push 'tag'
  #   reducers[ 'tag' ] = 'tag'
  #.........................................................................................................
  for mixin in mixins
    for key, value of mixin
      continue if ( key in exclude ) or ( value is undefined and reducer isnt 'assign' )
      reducer = reducers[ key ] ? reducer_fallback
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
          throw new Error "expected a POD, got a #{CND.type_of value}" unless CND.isa_pod value
          target = ( R[ key ] ?= {} )
          target[ sub_key ] = sub_value for sub_key, sub_value of value
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
        when 'function' then ( cache[ key ] ?= [] ).push value
        #...................................................................................................
        else throw new Error "unknown reducer #{rpr reducer}"
  #.........................................................................................................
  ### tags ###
  for key, value of R
    continue unless key in tag_keys
    R[ key ] = reduce_tag R[ key ]
  #.........................................................................................................
  ### averages ###
  for key, [ sum, count, ] of averages
    R[ key ] = sum / count
  #.........................................................................................................
  ### functions ###
  for key, values of cache
    R[ key ] = functions[ key ] values, R
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
MULTIMIX.use = ( custom_reducers... ) ->
  ### Returns a version of mix that uses the reducers passed in to `use`; the resulting reducer is
  derived form the reducers list by applying `mix`. Turtles. ###
  custom_reducers.splice 0, 0, { '*': 'assign', }
  reducers        = MULTIMIX.mix MULTIMIX, null, custom_reducers
  R               = ( mixins... ) -> MULTIMIX.mix R, reducers, mixins
  R.tools         = MULTIMIX.TOOLS
  R.use           = MULTIMIX.use
  return R

#-----------------------------------------------------------------------------------------------------------
module.exports = { mix: MULTIMIX.use(), }








