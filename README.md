

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

## Links

* [jeremyckahn/inherit-by-proxy.js](https://gist.github.com/jeremyckahn/5552373)
* [JS Objects: Distractions](https://davidwalsh.name/javascript-objects-distractions)
* [JS Objects: De"construct"ion](https://davidwalsh.name/javascript-objects-deconstruction)

## Motivation

"JavaScript's prototypal inheritance is vastyl simpler than Classical OOP"<sup>*[citation needed]*</sup>.

[Is it](https://davidwalsh.name/javascript-objects-deconstruction)?

![](https://raw.githubusercontent.com/loveencounterflow/multimix/master/artwork/JavaScriptObjects--Full.png)





