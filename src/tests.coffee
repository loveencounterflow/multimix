

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
    T.ok CND.is_subset ( Object.keys x.TOOLS ), [ 'normalize_tag', 'unique', 'append', 'meld', 'reduce_tag', ]
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
  #.........................................................................................................
  options_user =
    primes:     [ 7, 11, 13, ]
    zoom:       '85%'
    fonts:
      files:
        'ComicSans':  'MSComicSans.ttf'
    words:
      supercalifragilistic: 20
    speed:      50
    weight:     123
  #.........................................................................................................
  reducers =
    primes: 'append'
    words:  'merge'
    speed:  'average'
    weight: 'add'
    zoom:   ( zoom_percentages ) ->
      R = 1
      for percentage in zoom_percentages
        R *= ( parseFloat percentage ) / 100
      return "#{( R * 100 ).toFixed 2}%"
  #.........................................................................................................
  mix_options = mix.use reducers
  options     = mix_options options_base, options_user
  urge '5543', options
  T.ok options[ 'paths'   ] is options_base[ 'paths' ]
  T.ok options[ 'fonts'   ] is options_user[ 'fonts' ]
  T.eq options[ 'primes'  ], [ 2, 3, 5, 7, 11, 13, ]
  T.eq options[ 'zoom'    ], '106.25%'
  T.eq options[ 'words'   ], { foo: 3, bar: 3, supercalifragilistic: 20 }
  T.eq options[ 'speed'   ], 75
  T.eq options[ 'weight'  ], 579
  help mix.TOOLS
  help mix.REDUCERS
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "options example (3)" ] = ( T ) ->
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
  #.........................................................................................................
  options_user =
    primes:     [ 7, 11, 13, ]
    zoom:       '85%'
    # paths:
    #   app:      '~/sample'
    #   fonts:    '~/.fonts'
    fonts:
      files:
        'ComicSans':  'MSComicSans.ttf'
    words:
      supercalifragilistic: 20
    #   sizes:
    #     unit:   'pt'
    #     steps:  [ 8, 10, 11, 12, 14, 16, 18, 24, ]
  #.........................................................................................................
  reducers =
    primes: 'append'
    words:  'merge'
    zoom:   ( zoom_percentages ) ->
      R = 1
      for percentage in zoom_percentages
        R *= ( parseFloat percentage ) / 100
      return "#{( R * 100 ).toFixed 2}%"
  #.........................................................................................................
  mix_options = mix.use reducers
  options     = mix_options options_base, options_user
  urge '5543', options
  T.ok options[ 'paths'   ] is options_base[ 'paths' ]
  T.ok options[ 'fonts'   ] is options_user[ 'fonts' ]
  T.eq options[ 'primes'  ], [ 2, 3, 5, 7, 11, 13, ]
  T.eq options[ 'zoom'    ], '106.25%'
  T.eq options[ 'words'   ], { foo: 3, bar: 3, supercalifragilistic: 20 }
  help mix.TOOLS
  help mix.REDUCERS
  #.........................................................................................................
  return null


############################################################################################################
unless module.parent?
  # debug '0980', JSON.stringify ( Object.keys @ ), null, '  '
  include = [
    "demo (1)"
    "options example (1)"
    "options example (2)"
    ]
  @_prune()
  @_main()

  # debug Object.keys MULTIMIX
  # debug Object.keys mix
  # debug Object.keys mix.tools

  # @[ "options example" ]()









