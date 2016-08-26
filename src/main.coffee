

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


warn "introduce json, xjson methods for faster copying of known-to-be-ok values"
warn "reducer keys: '*' (main), '*/*' (any fields), '**' (main and fields)?"

#-----------------------------------------------------------------------------------------------------------
MULTIMIX          = {}
MULTIMIX.TOOLS    = require './tools'
MULTIMIX.REDUCERS = require './reducers'
MULTIMIX.COPIERS  = require './copiers'

#-----------------------------------------------------------------------------------------------------------
MULTIMIX._get_seed = ( L, S, seed, do_copy ) ->
  #.........................................................................................................
  if do_copy
    type          = CND.type_of seed
    description   = L.type_descriptions[ type ] ? L.type_descriptions[ σ_unknown_type ]
    { has_fields
      copy      } = description
    return copy.call L, S, seed
  #.........................................................................................................
  ### TAINT consider to call with `S` for consistency ###
  seed = seed() if CND.isa_function seed
  return seed

#-----------------------------------------------------------------------------------------------------------
MULTIMIX.mix = ( L, mixins, reducers, root = null, selector = [] ) ->
  #.........................................................................................................
  return null if mixins.length is 0
  [ mixin_seed
    mixin_tail... ]   = mixins
  reducers_seed       = reducers?[ 'seed' ]
  S                   = L.REDUCERS[ σ_new_state ] reducers, mixins
  #.........................................................................................................
  if reducers_seed? then  seed = MULTIMIX._get_seed L, S, reducers_seed, no
  else                    seed = MULTIMIX._get_seed L, S,    mixin_seed, yes
  #.........................................................................................................
  S.seed  = seed
  root   ?= seed
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
do ->
  #.........................................................................................................
  copy_id             = ( P... ) -> MULTIMIX.COPIERS.id             P...
  copy_object         = ( P... ) -> MULTIMIX.COPIERS.object         P...
  copy_list           = ( P... ) -> MULTIMIX.COPIERS.list           P...
  copy_map            = ( P... ) -> MULTIMIX.COPIERS.map            P...
  copy_set            = ( P... ) -> MULTIMIX.COPIERS.set            P...
  copy_by_constructor = ( P... ) -> MULTIMIX.COPIERS.by_constructor P...
  dont_copy           = ( P... ) -> MULTIMIX.COPIERS.dont           P...
  #.........................................................................................................
  MULTIMIX.type_descriptions =
    #.........................................................................................................
    boolean:     { type: 'boolean',       has_fields: no,  copy: copy_id,                 }
    null:        { type: 'null',          has_fields: no,  copy: copy_id,                 }
    text:        { type: 'text',          has_fields: no,  copy: copy_id,                 }
    undefined:   { type: 'undefined',     has_fields: no,  copy: copy_id,                 }
    infinity:    { type: 'infinity',      has_fields: no,  copy: copy_id,                 }
    number:      { type: 'number',        has_fields: no,  copy: copy_id,                 }
    nan:         { type: 'nan',           has_fields: no,  copy: copy_id,                 }
    #.........................................................................................................
    pod:         { type: 'pod',           has_fields: yes, copy: copy_object,             }
    list:        { type: 'list',          has_fields: yes, copy: copy_list,               }
    map:         { type: 'map',           has_fields: yes, copy: copy_map,                }
    set:         { type: 'set',           has_fields: yes, copy: copy_set,                }
    #.........................................................................................................
    date:        { type: 'date',          has_fields: yes, copy: copy_by_constructor,     }
    regex:       { type: 'regex',         has_fields: yes, copy: copy_by_constructor,     }
    #.........................................................................................................
    buffer:      { type: 'buffer',        has_fields: yes, copy: dont_copy,               }
    arraybuffer: { type: 'arraybuffer',   has_fields: yes, copy: dont_copy,               }
    error:       { type: 'error',         has_fields: yes, copy: dont_copy,               }
    function:    { type: 'function',      has_fields: yes, copy: dont_copy,               }
    symbol:      { type: 'symbol',        has_fields: no,  copy: dont_copy,               }
    #.........................................................................................................
    # These do not work at the time being:
    weakmap:     { type: 'weakmap',       has_fields: no,  copy: dont_copy,               }
    generator:   { type: 'generator',     has_fields: no,  copy: dont_copy,               }
    arguments:   { type: 'arguments',     has_fields: no,  copy: dont_copy,               }
    global:      { type: 'global',        has_fields: no,  copy: dont_copy,               }

#-----------------------------------------------------------------------------------------------------------
MULTIMIX.type_descriptions[ σ_unknown_type ] =
  type:       σ_unknown_type
  has_fields: no
  copy:       MULTIMIX.COPIERS.dont


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
module.exports = { mix: MULTIMIX.use(), }








