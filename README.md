

![](https://raw.githubusercontent.com/loveencounterflow/multimix/master/artwork/multimix.png)

# MultiMix

An ES6 `class` with some metaprogramming capabilities:

* easy to mixin instance methods from an arbitrary number of objects;
* easy to mixin static (class) methods from an arbitrary number of objects;
* sample implementation for a kind of 'keymethod proxies' (essentially instance method with custum special
  behavior);
* ability to 'export' an object with methods bound to a particular instance (great in conjunction with ES6
  object destructuring).

Implementation was inspired by / copy-pasted from [Chapter 3 of *The Little Book on
CoffeeScript*](https://arcturo.github.io/library/coffeescript/03_classes.html).

## Usage

Have a look at [the demo]():

```coffee
Multimix = require '../..'

#=========================================================================================================
# SAMPLE OBJECTS WITH INSTANCE METHODS, STATIC METHODS
#---------------------------------------------------------------------------------------------------------
object_with_class_properties =
  find:   ( id    ) -> info "class method 'find()'", ( k for k of @ )
  create: ( attrs ) -> info "class method 'create()'", ( k for k of @ )

#---------------------------------------------------------------------------------------------------------
object_with_instance_properties =
  save: -> info "instance method 'save()'", ( k for k of @ )

#=========================================================================================================
# CLASS DECLARATION
#---------------------------------------------------------------------------------------------------------
isa = ( type, xP... ) ->
  ### NOTE realistic method should throw error when `type` not in `specs` ###
  urge "µ1129 object #{rpr @instance_name} isa #{rpr type} called with #{rpr xP}"
  urge "µ1129 my @specs: #{rpr @specs}"
  urge "µ1129 spec for type #{rpr type}: #{rpr @specs[ type ]}"

#---------------------------------------------------------------------------------------------------------
class Intertype extends Multimix
  @extend   object_with_class_properties
  @include  object_with_instance_properties

  #-------------------------------------------------------------------------------------------------------
  constructor: ( @instance_name ) ->
    super()
    @specs = {}
    @declare type, value for type, value of @constructor.base_types
    @isa = Multimix.get_keymethod_proxy @, isa

  #-------------------------------------------------------------------------------------------------------
  declare: ( type, value ) ->
    whisper 'µ7474', 'declare', type, rpr value
    @specs[ type ] = value

  #-------------------------------------------------------------------------------------------------------
  @base_types =
    foo: 'spec for type foo'
    bar: 'spec for type bar'
```


## Links

* [jeremyckahn/inherit-by-proxy.js](https://gist.github.com/jeremyckahn/5552373)
* [JS Objects: Distractions](https://davidwalsh.name/javascript-objects-distractions)
* [JS Objects: De"construct"ion](https://davidwalsh.name/javascript-objects-deconstruction)

## Motivation

"JavaScript's prototypal inheritance is vastly simpler than class-based, 'classical' OOP".&nbsp;<sup>*[citation
needed]*</sup>

[Is it](https://davidwalsh.name/javascript-objects-deconstruction)?

![](https://raw.githubusercontent.com/loveencounterflow/multimix/master/artwork/JavaScriptObjects--Full.png)





