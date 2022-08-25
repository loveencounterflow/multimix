
# MultiMix

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [MultiMix](#multimix)
  - [To Do](#to-do)
  - [Is Done](#is-done)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->



![](https://raw.githubusercontent.com/loveencounterflow/multimix/master/artwork/multimix.png)

# MultiMix

* Objects with auto-generated property chains

* class `Hedge`
  * purpose: enable turning property access to function calls
    * propoerties may be predefined
    * or auto-generated, either
      * as plain objects
      * or by calling a custom factory function
    * example:

      ```coffee
      handler = ( hedges, a, b, c ) ->
        log hedges, [ a, b, c, ]
        return null
      h = new Hedge { handler, }
      h.foo
      # [ 'foo',  ]
      ```

* since hubs and properties are proxies, can do things on property access, no call needed, so both `d.foo`
  and `d.foo 42` can potentially do things



* `cfg`:

  * `cfg.handler`: mandatory property; function to be called on prop access, call, or both
    * `d = new Multimix { handler, }` returns the handler wrapped into a proxy
    * the `Multimix` instance is accessible as `d[Multimix.symbol]`. `Multimix.symbol` is a private symbol
      and thus guaranteed not to overwrite or shadow an existing property
    * existing properties of `handler` will be returned
    * non-existant properties of `handler` will be auto-generated on first access; these will be functions
      that, when called with any number of arguments `f P...`, will in turn call `handler props, P...`
    * `handler` will be called in the context of `hub` where given; otherwise, its context will be the
      `Multimix` instance.

  * `hub`: optional reference / base object (re 'hub': as if props were spokes)

  * `cfg.create`:
    * `true` (default): missing props will be auto-generated as functions that call `handler` in the context
      of `cfg.hub` where given (or else the `Multimix` instance)
    * `false`: no missing props will be generated
    * a function: to be called as `create key, target` when a new property is first accessed; this function
      may or may not create a new property as seen fit. The MultiMix proxy will, at any rate, return
      `target[ key ]` which may or may not be `undefined`.

  * `cfg.strict`: (default `false`) if set to `true`, trying to access an unset property will cause an
    error. This setting is only valid when used in conjunction with `create: false`.

  * `cfg.oneshot`: (default `false`) if set to `true`, trying to re-assign any value to an existing property
    will cause an error

  * `cfg.deletion`: (default `true`) if set to `false`, trying to delete any property will cause an error

  * `cfg.hide`: (default `true`) if set to `true`, will make auto-generated properties non-enumerable so
    they don't show up in console output

## To Do

* **[–]** documentation

## Is Done

* **[+]** `cfg.strict`
* **[+]** `cfg.oneshot`
* **[+]** `cfg.deletion`



