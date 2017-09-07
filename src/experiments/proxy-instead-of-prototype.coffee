

Great discussion:
https://gist.github.com/jeremyckahn/5552373

Must read:
https://davidwalsh.name/javascript-objects-distractions


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'KBM/APP'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge

x = ( x ) -> "helo world #{@name} #{x}"
base = { name: 'my name', }
# x.__proto__ = base
# Object.setPrototypeOf x, base
x = Object.create x, { name: { value: 'me', }, }

settings =
  get: ( target, property ) ->
    debug '11101-1', rpr target
    debug '11101-2', rpr property
    return if property of target then target[ property ] else '!!!!!'

proxy = new Proxy x, settings

# help x 42
# help x.foo
# help proxy 42
# help proxy.foo

# debug ->
# debug new -> ( -> )
# debug ( new -> ( -> ) ) 42

X = ->
  @name = 'didi'
  return ( -> '*' + @name + '*' ).bind @

base = { name: 'lulu', age: 108, f: -> "my name is #{@name}, my age is #{@age}" }
new_x = ->
  R = ( -> '*' + @name + '*' ).bind base
  # R.__proto__ = base
  Object.setPrototypeOf R, base
  return R


# x = new X()
x = new_x()
whisper x
whisper ( name for name of x )
whisper x()
whisper x.f()



###
https://stackoverflow.com/a/31236132/7568091
###

```
function getDesc (obj, prop) {
  var desc = Object.getOwnPropertyDescriptor(obj, prop);
  return desc || (obj=Object.getPrototypeOf(obj) ? getDesc(obj, prop) : void 0);
}
function multiInherit (...protos) {
  return Object.create(new Proxy(Object.create(null), {
    has: (target, prop) => protos.some(obj => prop in obj),
    get (target, prop, receiver) {
      var obj = protos.find(obj => prop in obj);
      return obj ? Reflect.get(obj, prop, receiver) : void 0;
    },
    set (target, prop, value, receiver) {
      var obj = protos.find(obj => prop in obj);
      return Reflect.set(obj || Object.create(null), prop, value, receiver);
    },
    *enumerate (target) { yield* this.ownKeys(target); },
    ownKeys(target) {
      var hash = Object.create(null);
      for(var obj of protos) for(var p in obj) if(!hash[p]) hash[p] = true;
      return Object.getOwnPropertyNames(hash);
    },
    getOwnPropertyDescriptor(target, prop) {
      var obj = protos.find(obj => prop in obj);
      var desc = obj ? getDesc(obj, prop) : void 0;
      if(desc) desc.configurable = true;
      return desc;
    },
    preventExtensions: (target) => false,
    defineProperty: (target, prop, desc) => false,
  }));
}
```

###

Explanation

A proxy object consists of a target object and some traps, which define custom behavior for fundamental
operations.

When creating an object which inherits from another one, we use Object.create(obj). But in this case we want
multiple inheritance, so instead of obj I use a proxy that will redirect fundamental operations to the
appropriate object.

I use these traps:

* The has trap is a trap for the in operator. I use some to check if at least one prototype contains the
  property.

* The get trap is a trap for getting property values. I use find to find the first prototype which contains
  that property, and I return the value, or call the getter on the appropriate receiver. This is handled by
  Reflect.get. If no prototype contains the property, I return undefined.

* The set trap is a trap for setting property values. I use find to find the first prototype which contains
  that property, and I call its setter on the appropriate receiver. If there is no setter or no prototype
  contains the property, the value is defined on the appropriate receiver. This is handled by Reflect.set.

* The enumerate trap is a trap for for...in loops. I iterate the enumerable properties from the first
  prototype, then from the second, and so on. Once a property has been iterated, I store it in a hash table
  to avoid iterating it again. Warning: This trap has been removed in ES7 draft and is deprecated in
  browsers.

* The ownKeys trap is a trap for Object.getOwnPropertyNames(). Since ES7, for...in loops keep calling
  [[GetPrototypeOf]] and getting the own properties of each one. So in order to make it iterate the
  properties of all prototypes, I use this trap to make all enumerable inherited properties appear like own
  properties.

* The getOwnPropertyDescriptor trap is a trap for Object.getOwnPropertyDescriptor(). Making all enumerable
  properties appear like own properties in the ownKeys trap is not enough, for...in loops will get the
  descriptor to check if they are enumerable. So I use find to find the first prototype which contains that
  property, and I iterate its prototypical chain until I find the property owner, and I return its
  descriptor. If no prototype contains the property, I return undefined. The descriptor is modified to make
  it configurable, otherwise we could break some proxy invariants.

* The preventExtensions and defineProperty traps are only included to prevent these operations from
  modifying the proxy target. Otherwise we could end up breaking some proxy invariants.

There are more traps available, which I don't use

* The getPrototypeOf trap could be added, but there is no proper way to return the multiple prototypes. This
  implies instanceof won't work neither. Therefore, I let it get the prototype of the target, which
  initially is null.

* The setPrototypeOf trap could be added and accept an array of objects, which would replace the prototypes.
  This is left as an exercice for the reader. Here I just let it modify the prototype of the target, which
  is not much useful because no trap uses the target.

* The deleteProperty trap is a trap for deleting own properties. The proxy represents the inheritance, so
  this wouldn't make much sense. I let it attempt the deletion on the target, which should have no property
  anyway.

* The isExtensible trap is a trap for getting the extensibility. Not much useful, given that an invariant
  forces it to return the same extensibility as the target. So I just let it redirect the operation to the
  target, which will be extensible.

* The apply and construct traps are traps for calling or instantiating. They are only useful when the target
  is a function or a constructor.

Example
###

```
// Creating objects
var o1, o2, o3,
    obj = multiInherit(o1={a:1}, o2={b:2}, o3={a:3, b:3});

// Checking property existences
'a' in obj; // true   (inherited from o1)
'b' in obj; // true   (inherited from o2)
'c' in obj; // false  (not found)

// Setting properties
obj.c = 3;

// Reading properties
obj.a; // 1           (inherited from o1)
obj.b; // 2           (inherited from o2)
obj.c; // 3           (own property)
obj.d; // undefined   (not found)

// The inheritance is "live"
obj.a; // 1           (inherited from o1)
delete o1.a;
obj.a; // 3           (inherited from o3)

// Property enumeration
for(var p in obj) p; // "c", "b", "a"
```






