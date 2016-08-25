


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'MULTIMIX/COPIERS'
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
@dont = ( S, x ) -> throw new Error "unable to copy value of type #{CND.type_of x}"

#-----------------------------------------------------------------------------------------------------------
@id = ( S, x ) ->
  S.seen.set x, x
  return x

#-----------------------------------------------------------------------------------------------------------
@object = ( S, x, seed ) ->
  ### shamelessly copied from https://github.com/nrn/universal-copy ###
  R = seed ? Object.create Object.getPrototypeOf x
  S.seen.set x, R
  if      Object.isFrozen     x then Object.freeze            R
  if      Object.isSealed     x then Object.seal              R
  unless  Object.isExtensible x then Object.preventExtensions R
  return R

#-----------------------------------------------------------------------------------------------------------
@list = ( S, x ) -> @object S, x, new Array x.length
@set  = ( S, x ) -> @object S, x, new Set x
@map  = ( S, x ) -> @object S, x, new Map x

#-----------------------------------------------------------------------------------------------------------
@by_constructor = ( S, x ) ->
  ### shamelessly copied from https://github.com/nrn/universal-copy ###
  R = new x.constructor x
  S.seen.set x, R
  return R


