

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

Have a look at [the
demo](https://github.com/loveencounterflow/multimix/blob/master/src/experiments/demo.coffee):

* `class X extends Multimix` gives you a class with the following static methods inherited through
  `Multimix`:

  *  `<class>.extend: ( object ) ->`—extends class with the properties of `object` (class-level mixin).
  *  `<class>.include: ( object ) ->`—extends instances with the properties of `object` (instance-level
     mixin).
  *  `<class>.get_keymethod_proxy = ( bind_target, f ) ->`—produces an instance method `f` which will
     translate calls from immediate attributes (as in, `f.some_text some_value`) to calls to `f` proper,
     using the attribute name as first argument: `f some_text, some_value`. I needed this for a specific
     purpose and included the code as a demo how to implement such a thing.
  *  `export_methods: ->`—when called on an instance, returns an object with bound instance methods; this
     allows to 'export' instance methods into a namespace without fearing 'JavaScript method tear-off
     symptome':

     ```coffee
     my_instance = new My_class
     { method_a
       method_b } = my_instance.export_methods()
     # now you can use `method_a`, `method_b` without prefixing them with `my_instance`:
     method_a 42
     ```

Code:

```coffee
Multimix = require 'multimix'

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

##########################################################################################################
intertype_1 = new Intertype
intertype_2 = new Intertype

info 'µ002-1', Intertype.base_types
info 'µ002-2', intertype_1.declare 'new_on_it1', 'a new hope'
info 'µ002-3', 'intertype_1.specs', intertype_1.specs
info 'µ002-4', 'intertype_2.specs', intertype_2.specs
info 'µ002-5', intertype_1.isa 'new_on_it1', 1, 2, 3
info 'µ002-6', intertype_1.isa.new_on_it1    1, 2, 3
info 'µ002-7', intertype_2.isa 'new_on_it1', 1, 2, 3
info 'µ002-8', intertype_2.isa.new_on_it1    1, 2, 3
{ isa, declare, } = intertype_1.export_methods()
info 'µ002-9', isa 'new_on_it1', 1, 2, 3
info 'µ002-10', isa.new_on_it1    1, 2, 3
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





