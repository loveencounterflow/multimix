

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


#-----------------------------------------------------------------------------------------------------------
MULTIMIX          = {}
MULTIMIX.TOOLS    = require './tools'
MULTIMIX.REDUCERS = require './reducers'
MULTIMIX.COPIERS  = require './copiers'

#-----------------------------------------------------------------------------------------------------------
MULTIMIX.mix = ( L, mixins, reducers, root = null, selector = [] ) ->
  #.........................................................................................................
  debug '23764', mixins
  return null if mixins.length is 0
  [ seed
    mixins... ]   = mixins
  type            = CND.type_of seed
  description     = L.type_descriptions[ type ] ? L.type_descriptions[ σ_unknown_type ]
  debug '83429', description
  { attributes
    copy        } = description
  seen            = new Map()
  R               = copy.call L, seed, seen
  #.........................................................................................................
  return R unless attributes
  throw 'not implemented'
  #.........................................................................................................
  S               = L.REDUCERS[ σ_new_state ] reducers, seen
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
        R[ rd_key ] = MULTIMIX.mix L, partial_mixins, rd_value, root, selector
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
      continue if L.REDUCERS[ σ_reject ] S, mx_key, mx_value
      unless ( reducer = L.REDUCERS[ S.reducer_name ] )?
        throw new Error "unknown reducer #{rpr S.reducer_name}"
      reducer.call L.REDUCERS, S, mx_key, mx_value
  #.........................................................................................................
  L.REDUCERS[ σ_finalize ] S
  #.........................................................................................................
  # S.path    = null
  # S.root    = null
  # S.current = null
  return R

#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
###
  '[object Object]': copyObject,
  '[object Array]': copyArray,
  '[object Error]': justDont,
  '[object Map]': copyMap,
  '[object Set]': copySet,

  '[object Promise]': justDont,
  '[object XMLHttpRequest]': justDont,
  '[object NodeList]': copyArray,
  '[object ArrayBuffer]': copySlice,
  '[object Int8Array]': copyConstructor,
  '[object Uint8Array]': copyConstructor,
  '[object Uint8ClampedArray]': copyConstructor,
  '[object Int16Array]': copyConstructor,
  '[object Uint16Array]': copyConstructor,
  '[object Int32Array]': copyConstructor,
  '[object Uint32Array]': copyConstructor,
  '[object Float32Array]': copyConstructor,
  '[object Float64Array]': copyConstructor
###

#-----------------------------------------------------------------------------------------------------------
MULTIMIX.type_descriptions =
  #.........................................................................................................
  boolean:     { type: 'boolean',       attributes: no,  copy: MULTIMIX.COPIERS.id, }
  null:        { type: 'null',          attributes: no,  copy: MULTIMIX.COPIERS.id, }
  text:        { type: 'text',          attributes: no,  copy: MULTIMIX.COPIERS.id, }
  undefined:   { type: 'undefined',     attributes: no,  copy: MULTIMIX.COPIERS.id, }
  infinity:    { type: 'infinity',      attributes: no,  copy: MULTIMIX.COPIERS.id, }
  number:      { type: 'number',        attributes: no,  copy: MULTIMIX.COPIERS.id, }
  nan:         { type: 'nan',           attributes: no,  copy: MULTIMIX.COPIERS.id, }
  #.........................................................................................................
  pod:         { type: 'pod',           attributes: yes, copy: MULTIMIX.COPIERS.object, }
  #.........................................................................................................
  date:        { type: 'date',          attributes: yes, copy: MULTIMIX.COPIERS.by_constructor, }
  regex:       { type: 'regex',         attributes: yes, copy: MULTIMIX.COPIERS.by_constructor, }
  #.........................................................................................................
  map:         { type: 'map',           attributes: yes, copy: MULTIMIX.COPIERS.dont, }
  set:         { type: 'set',           attributes: yes, copy: MULTIMIX.COPIERS.dont, }
  list:        { type: 'list',          attributes: yes, copy: MULTIMIX.COPIERS.dont, }
  buffer:      { type: 'buffer',        attributes: yes, copy: MULTIMIX.COPIERS.dont, }
  arraybuffer: { type: 'arraybuffer',   attributes: yes, copy: MULTIMIX.COPIERS.dont, }
  error:       { type: 'error',         attributes: yes, copy: MULTIMIX.COPIERS.dont, }
  function:    { type: 'function',      attributes: yes, copy: MULTIMIX.COPIERS.dont, }
  symbol:      { type: 'symbol',        attributes: no,  copy: MULTIMIX.COPIERS.dont, }
  #.........................................................................................................
  # These do not work at the time being:
  weakmap:     { type: 'weakmap',       attributes: no,  copy: MULTIMIX.COPIERS.dont, }
  generator:   { type: 'generator',     attributes: no,  copy: MULTIMIX.COPIERS.dont, }
  arguments:   { type: 'arguments',     attributes: no,  copy: MULTIMIX.COPIERS.dont, }
  global:      { type: 'global',        attributes: no,  copy: MULTIMIX.COPIERS.dont, }

#-----------------------------------------------------------------------------------------------------------
MULTIMIX.type_descriptions[ σ_unknown_type ] =
  type:       σ_unknown_type
  attributes: no
  copy:       MULTIMIX.COPIERS.dont


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
MULTIMIX.use = ( custom_reducers... ) ->
  ### Returns a version of `mix` that uses the reducers passed in to `use`; the resulting reducer is
  derived from the reducers list by applying `mix`. Turtles. ###
  custom_reducers.splice 0, 0, { '*': 'assign', }
  reducers            = MULTIMIX.mix MULTIMIX, custom_reducers, null
  R                   = ( mixins... ) -> MULTIMIX.mix R, mixins, reducers
  R.TOOLS             = MULTIMIX.TOOLS
  R.REDUCERS          = MULTIMIX.REDUCERS
  R.COPIERS           = MULTIMIX.COPIERS
  R.type_descriptions = MULTIMIX.type_descriptions
  R.use               = MULTIMIX.use
  # R.deep_copy         = ( x ) -> CND.deep_copy x
  return R

#-----------------------------------------------------------------------------------------------------------
module.exports = { mix: MULTIMIX.use(), }








