

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'MULTIMIX/REDUCERS'
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
#...........................................................................................................
σ_new_state               = Symbol.for 'new_state'
σ_reject                  = Symbol.for 'reject'
σ_finalize                = Symbol.for 'finalize'


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@[ σ_new_state ] = ( reducers ) ->
  S                   = {}
  S.reducers          = reducers ? {}
  S.reducer_fallback  = S.reducers[ '*' ] ? 'assign'
  #.........................................................................................................
  S.cache             = {}
  S.averages          = {}
  S.tag_keys          = ( key for key, value of S.reducers when value is 'tag' )
  S.skip              = [] # ( key for key in [ 'idx', 'id', 'lo', 'hi', 'size', ] when not ( key of S.reducers ) )
  S.functions         = {}
  S.path              = null
  S.root              = null
  S.current           = null
  #.........................................................................................................
  ### TAINT presently the reducers namespace has mixin keys as keys except for the special
  key '*'. This severly restricts the expressiveness of the configuration. Solutions:
  * move mixin keys to a segregated object
  * use sigils like '~' or syntax like '<type>' for special keys
  * reserve one other special key for all special keys
  ###
  #.........................................................................................................
  for key, reducer of S.reducers
    if reducer is 'include'
      S.reducers[ key   ] = S.reducer_fallback
      continue
    if CND.isa_function reducer
      S.functions[  key ] = reducer
      S.reducers[   key ] = 'function'
  #.........................................................................................................
  return S

#-----------------------------------------------------------------------------------------------------------
@[ σ_finalize ] = ( S ) ->
  ### tags ###
  for key, value of S.current
    continue unless key in S.tag_keys
    S.current[ key ] = TOOLS.reduce_tag S.current[ key ]
  #.........................................................................................................
  ### averages ###
  for key, [ sum, count, ] of S.averages
    S.current[ key ] = sum / count
  #.........................................................................................................
  ### functions ###
  for key, values of S.cache
    S.current[ key ] = S.functions[ key ] values, S
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ σ_reject ] = ( S, key, value ) ->
  return ( key in S.skip ) or ( value is undefined and S.reducer_name isnt 'assign' )


#===========================================================================================================
# REDUCERS
#-----------------------------------------------------------------------------------------------------------
@assign = ( S, R, key, value ) ->
  if value is undefined then delete R[ key ]
  else                              R[ key ] = value
  return null

#-----------------------------------------------------------------------------------------------------------
@skip = ( S, R, key, value ) -> null

#-----------------------------------------------------------------------------------------------------------
@merge = ( S, R, key, value ) ->
  throw new Error "expected a POD, got a #{CND.type_of value}" unless CND.isa_pod value
  target = ( R[ key ] ?= {} )
  target[ sub_key ] = sub_value for sub_key, sub_value of value
  return null

#-----------------------------------------------------------------------------------------------------------
@append = ( S, R, key, value ) ->
  ### TAINT consider to use `Symbol.isConcatSpreadable` in the future ###
  target = ( R[ key ] ?= [] )
  if CND.isa_list then  target.splice target.length, 0, value...
  else                  target.push                     value
  return null

#-----------------------------------------------------------------------------------------------------------
@list = ( S, R, key, value ) ->
  ( R[ key ] ?= [] ).push value
  return null

#-----------------------------------------------------------------------------------------------------------
@add = ( S, R, key, value ) ->
  R[ key ] = ( R[ key ] ? 0 ) + value
  return null

#-----------------------------------------------------------------------------------------------------------
@average = ( S, R, key, value ) ->
  target      = S.averages[ key ] ?= [ 0, 0, ]
  target[ 0 ] = target[ 0 ] + value
  target[ 1 ] = target[ 1 ] + 1
  return null

#-----------------------------------------------------------------------------------------------------------
@tag = ( S, R, key, value ) ->
  TOOLS.meld ( target = R[ key ] ?= [] ), value
  return null

#-----------------------------------------------------------------------------------------------------------
@function = ( S, R, key, value ) ->
  ### Cache current value for later processing by `σ_finalize`: ###
  ( S.cache[ key ] ?= [] ).push value
  return null

