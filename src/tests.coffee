

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'MULTIMIX/TESTS'
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
test                      = require 'guy-test'
#...........................................................................................................
# MULTIMIX                  = require './main'
{ mix }                   = require './main'


#===========================================================================================================
# HELPERS
#-----------------------------------------------------------------------------------------------------------
s = ( x ) -> JSON.stringify x, null, '  '
t = ( x ) -> JSON.stringify x

#-----------------------------------------------------------------------------------------------------------
@_prune = ->
  for name, value of @
    continue if name.startsWith '_'
    delete @[ name ] unless name in include
  return null

#-----------------------------------------------------------------------------------------------------------
@_main = ->
  test @, 'timeout': 3000


#===========================================================================================================
# TESTS
#-----------------------------------------------------------------------------------------------------------
@[ "demo (1)" ] = ( T ) ->
  #.........................................................................................................
  test_tools = ( T, x ) ->
    return T.fail "object has no property 'TOOLS'" unless x.TOOLS?
    T.ok CND.is_subset [ 'normalize_tag', 'unique', 'append', 'meld', ], ( Object.keys x.TOOLS )
    return null
  #.........................................................................................................
  test_tools T, mix
  my_mix = mix.use { primes: 'append' }
  test_tools T, my_mix
  #.........................................................................................................
  a =
    id:           'a'
    primes:       [ 2, 3, 5, 7, ]
    report:       -> t { @id, @primes, }
  #.........................................................................................................
  b = my_mix a, { id: 'b', primes: [ 13, 17, 23, ], }
  #.........................................................................................................
  T.eq a[ 'primes' ], [2,3,5,7]
  T.eq b[ 'primes' ], [2,3,5,7,13,17,23]
  T.eq a.report(), '{"id":"a","primes":[2,3,5,7]}'
  T.eq b.report(), '{"id":"b","primes":[2,3,5,7,13,17,23]}'
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "options example (1)" ] = ( T ) ->
  #.........................................................................................................
  options_base =
    zoom:       '125%'
    paths:
      app:      '~/sample'
      fonts:    '~/.fonts'
    fonts:
      files:
        'Arial':  'HelveticaNeue.ttf'
      sizes:
        unit:   'pt'
        steps:  [ 8, 10, 11, 12, 14, 16, 18, 24, ]
  #.........................................................................................................
  options_user =
    zoom:       '85%'
    fonts:
      files:
        'ComicSans':  'MSComicSans.ttf'
  #.........................................................................................................
  options = mix options_base, options_user
  #.........................................................................................................
  T.ok options[ 'paths' ] is options_base[ 'paths' ]
  T.ok options[ 'fonts' ] is options_user[ 'fonts' ]
  T.eq options[ 'zoom' ], options_user[ 'zoom' ]
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "options example (2)" ] = ( T ) ->
  #.........................................................................................................
  options_base =
    primes:     [ 2, 3, 5, ]
    zoom:       '125%'
    paths:
      app:      '~/sample'
      fonts:    '~/.fonts'
    fonts:
      files:
        'Arial':  'HelveticaNeue.ttf'
      sizes:
        unit:   'pt'
        steps:  [ 8, 10, 11, 12, 14, 16, 18, 24, ]
    words:
      foo:      3
      bar:      3
    speed:      100
    weight:     456
    tags:       [ 'alpha', 'beta', 'gamma', 'delta', ]
    fruit:      'banana'
  #.........................................................................................................
  options_user =
    primes:           [ 7, 11, 13, ]
    zoom:             '85%'
    'only-here':      yes
    'to-be-skipped':  yes
    fonts:
      files:
        'ComicSans':  'MSComicSans.ttf'
    words:
      supercalifragilistic: 20
    speed:            50
    weight:           123
    tags:             [ '-alpha', 'beta', 'gamma', 'epsilon', ]
    fruit:            'pineapple'
  #.........................................................................................................
  reducers =
    primes:           'append'
    words:            'merge'
    speed:            'average'
    weight:           'add'
    'to-be-skipped':  'skip'
    tags:             'tag'
    fruit:            'list'
    zoom:             ( zoom_percentages ) ->
      R = 1
      for percentage in zoom_percentages
        R *= ( parseFloat percentage ) / 100
      return "#{( R * 100 ).toFixed 2}%"
  #.........................................................................................................
  mix_options = mix.use reducers
  options     = mix_options options_base, options_user
  # urge '5543', options
  T.ok options[ 'paths'         ] is options_base[ 'paths' ]
  T.ok options[ 'fonts'         ] is options_user[ 'fonts' ]
  T.eq options[ 'primes'        ], [ 2, 3, 5, 7, 11, 13, ]
  T.eq options[ 'zoom'          ], '106.25%'
  T.eq options[ 'words'         ], { foo: 3, bar: 3, supercalifragilistic: 20 }
  T.eq options[ 'speed'         ], 75
  T.eq options[ 'weight'        ], 579
  T.eq options[ 'tags'          ], [ 'delta', 'beta', 'gamma', 'epsilon', ]
  T.eq options[ 'only-here'     ], yes
  T.eq options[ 'to-be-skipped' ], undefined
  T.eq options[ 'fruit'         ], [ 'banana', 'pineapple', ]
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "options example (3)" ] = ( T ) ->
  #.........................................................................................................
  options_base =
    paths:
      app:      '~/sample'
      fonts:    '~/.fonts'
    fonts:
      files:
        'Arial':  'HelveticaNeue.ttf'
  #.........................................................................................................
  options_user =
    fonts:
      files:
        'ComicSans':  'MSComicSans.ttf'
  #.........................................................................................................
  outer_reducers = null
  fonts_reducers =
    files:            'merge'
  #.........................................................................................................
  options_user_copy             = Object.assign {}, options_user
  options_user_copy[ 'fonts' ]  = ( mix.use fonts_reducers ) options_base[ 'fonts' ], options_user_copy[ 'fonts' ]
  options                       = ( mix.use outer_reducers ) options_base, options_user_copy
  # urge '7631', t options
  # T.eq options[ 'fonts' ], {"fonts":{"files":{"Arial":"HelveticaNeue.ttf","ComicSans":"MSComicSans.ttf"}}}
  T.eq options, {"paths":{"app":"~/sample","fonts":"~/.fonts"},"fonts":{"files":{"Arial":"HelveticaNeue.ttf","ComicSans":"MSComicSans.ttf"}}}
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "options example with nested reducers" ] = ( T ) ->
  #.........................................................................................................
  options_base =
    paths:
      app:      '~/sample'
      fonts:    '~/.fonts'
    fonts:
      files:
        'Arial':  'HelveticaNeue.ttf'
    foo:
      bar:
        baz:      42
  #.........................................................................................................
  options_user =
    fonts:
      files:
        'ComicSans':  'MSComicSans.ttf'
    alpha:
      beta:
        gamma:    108
  #.........................................................................................................
  reducers =
    fonts:
      files:      'merge'
    foo:
      bar:
        baz:      ( values, S ) -> S.path
    alpha:
      beta:
        gamma:    ( values, S ) -> S.path
  #.........................................................................................................
  options = ( mix.use reducers ) options_base, options_user
  urge '7631', t options
  T.eq options, {"fonts":{"files":{"Arial":"HelveticaNeue.ttf","ComicSans":"MSComicSans.ttf"}},"foo":{"bar":{"baz":"foo/bar/baz"}},"alpha":{"beta":{"gamma":"alpha/beta/gamma"}},"paths":{"app":"~/sample","fonts":"~/.fonts"}}
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "unused reducers must not cause entry" ] = ( T ) ->
  #.........................................................................................................
  options_base =
    foo:
      bar:
        baz:      42
  #.........................................................................................................
  options_user =
    fonts:
      files:
        'ComicSans':  'MSComicSans.ttf'
  #.........................................................................................................
  reducers =
    foo:
      bar:
        baz:      ( values, S ) -> S.path
    alpha:
      beta:
        gamma:    ( values, S ) -> S.path
    delta:        'list'
    qplah:
      gagh:       'append'
  #.........................................................................................................
  options = ( mix.use reducers ) options_base, options_user
  urge '7631', t options
  T.eq options, {"foo":{"bar":{"baz":"foo/bar/baz"}},"fonts":{"files":{"ComicSans":"MSComicSans.ttf"}}}
  #.........................................................................................................
  return null


############################################################################################################
unless module.parent?
  # debug '0980', JSON.stringify ( Object.keys @ ), null, '  '
  include = [
    "demo (1)"
    "options example (1)"
    "options example (2)"
    "options example (3)"
    "options example with nested reducers"
    "unused reducers must not cause entry"
    ]
  @_prune()
  @_main()

  # debug Object.keys MULTIMIX
  # debug Object.keys mix
  # debug Object.keys mix.tools

  # @[ "options example" ]()









