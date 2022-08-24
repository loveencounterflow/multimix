
# MultiMix

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [MultiMix](#multimix)
  - [To Do](#to-do)

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

* 'handler': function to be called on prop access, call, or both

* 'hub': optional reference / base object (re 'hub': as if props were spokes)


* `cfg`:

  * `cfg.create`:
    * `true` (default): missing props will be auto-generated as plain objects
    * `false`: no missing props will be generated
    * a function: to be called as `create key, target` when a new property is first accessed; the return
      value of this function will become then new property

  * `strict`: if set to `true`, trying to access an unset property will cause an error. This setting is only
    valid when used in conjunction with `create: false`.


## To Do

* **[–]** documentation
* **[–]** `cfg.oneshot`

## Is Done

* **[+]** `cfg.strict`



