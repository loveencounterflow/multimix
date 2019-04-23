
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'MULTIMIX/EXPERIMENTS/ES6-CLASSES-WITH.MIXINS'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge


#-----------------------------------------------------------------------------------------------------------
raw_example = ->

  ###


  ###

  ###

  let's integrate mixins into CoffeeScript's classes. We're going to define a class called Module that we can
  inherit from for mixin support. Module will have two static functions, @extend() and @include() which we can
  use for extending the class with static and instance properties respectively.

  ###

  #-----------------------------------------------------------------------------------------------------------
  moduleKeywords = [ 'extended', 'included', ]

  #-----------------------------------------------------------------------------------------------------------
  get_keymethod_proxy = ( f ) -> new Proxy f,
    get: ( target, key ) -> ( xP... ) -> target key, xP...

  #-----------------------------------------------------------------------------------------------------------
  class Module
    constructor: -> @classname = 'Module'

    #.........................................................................................................
    @extend: ( object ) ->
      for key, value of object when key not in moduleKeywords
        @[ key ] = value
      object.extended?.apply @
      return @

    #.........................................................................................................
    @include: ( object ) ->
      for key, value of object when key not in moduleKeywords
        # Assign properties to the prototype
        @::[ key ] = value
      object.included?.apply @
      return @

  ###

  The little dance around the moduleKeywords variable is to ensure we have callback support when mixins extend
  a class. Let's take a look at our Module class in action:

  ###

  #-----------------------------------------------------------------------------------------------------------
  object_with_class_properties =
    find:   ( id    ) -> info "class method 'find()'", ( k for k of @ )
    create: ( attrs ) -> info "class method 'create()'", ( k for k of @ )

  #-----------------------------------------------------------------------------------------------------------
  object_with_instance_properties =
    save: -> info "instance method 'save()'", ( k for k of @ )

  #-----------------------------------------------------------------------------------------------------------
  isa = get_keymethod_proxy ( type, P... ) ->
    info "µ1129 object #{rpr @instance_name} isa #{rpr type} called with #{rpr P}"
    info "µ1129 my @specs: #{rpr @specs}"

  #-----------------------------------------------------------------------------------------------------------
  class User extends Module
    @extend   object_with_class_properties
    @include  object_with_instance_properties
    @include { isa, }
    constructor: ( @instance_name ) ->
      super()
      @classname = 'User'
      @specs = {}
    instance_method_on_User: -> info "instance method 'instance_method_on_User()'", ( k for k of @ )
    declare: ( type, value ) -> @specs[ type ] = value

  #-----------------------------------------------------------------------------------------------------------
  class Refined_user extends User
    constructor: ->
      super()
      @classname = 'Refined_user'
      @get_classname = -> @classname
    # save: -> "method save() overwritten by Refined_user"
    instance_method_on_refined_user: -> info "instance method 'instance_method_on_refined_user()'", ( k for k of @ )

  debug "properties of class User", ( k for k of User )
  debug "properties of class User::", ( k for k of User:: )
  debug "properties of class Refined_user", ( k for k of Refined_user )
  debug "properties of class Refined_user::", ( k for k of Refined_user:: )

  #-----------------------------------------------------------------------------------------------------------
  # Usage:
  debug 'µ100-1', user = User.find 1
  debug 'µ100-2', user = new User()
  debug 'µ100-3', user.save()
  debug 'µ100-4', user.save.foobar = 42
  debug 'µ100-5', user.classname
  debug 'µ100-6', ruser = new Refined_user()
  debug 'µ100-7', ruser.instance_method_on_refined_user()
  debug 'µ100-8', ruser.save()
  debug 'µ100-9', ruser.save.foobar
  debug 'µ100-10', ruser.save is user.save
  debug 'µ100-11', ruser.classname
  debug 'µ100-12', ruser.get_classname()

  user_1 = new User 'user_1'
  user_1.declare 'user_1_type_A', 'type_A'
  user_1.declare 'user_1_type_B', 'type_B'
  user_2 = new User 'user_2'
  user_2.declare 'user_2_type_C', 'type_C'
  user_2.declare 'user_2_type_D', 'type_D'
  user_2.declare 'user_2_type_E', 'type_E'
  whisper '-'.repeat 108
  debug 'µ100-13', user_1
  debug 'µ100-14', user_1.isa 'type_A', 1
  debug 'µ100-15', user_1.isa.type_A, 1
  whisper '-'.repeat 108
  debug 'µ100-16', user_2
  debug 'µ100-17', user_2.isa 'type_A', 1
  debug 'µ100-18', user_2.isa.type_A, 1
  debug 'µ100-19', user_2.isa 'type_C', 1
  debug 'µ100-20', user_2.isa.type_C, 1


#-----------------------------------------------------------------------------------------------------------
rewritten_example = ->


  #===========================================================================================================
  # MODULE METACLASS provides static methods `@extend()`, `@include()`
  #-----------------------------------------------------------------------------------------------------------
  ### The little dance around the module_keywords variable is to ensure we have callback support when mixins
  extend a class. See https://arcturo.github.io/library/coffeescript/03_classes.html ###
  #-----------------------------------------------------------------------------------------------------------
  module_keywords = [ 'extended', 'included', ]

  #===========================================================================================================
  class Multimix

    #---------------------------------------------------------------------------------------------------------
    @extend: ( object ) ->
      for key, value of object when key not in module_keywords
        @[ key ] = value
      object.extended?.apply @
      return @

    #---------------------------------------------------------------------------------------------------------
    @include: ( object ) ->
      for key, value of object when key not in module_keywords
        # Assign properties to the prototype
        @::[ key ] = value
      object.included?.apply @
      return @

    #---------------------------------------------------------------------------------------------------------
    export_methods: ->
      ### Return an object with methods, bound to the current instance. ###
      R = {}
      for k, v of @
        continue unless v?.bind?
        if ( v[ isa_keymethod_proxy ] ? false )
          R[ k ] = _get_keymethod_proxy @, v
        else
          R[ k ] = v.bind @
      return R

  #===========================================================================================================
  # KEYMETHOD FACTORY
  #-----------------------------------------------------------------------------------------------------------
  _get_keymethod_proxy = ( bind_target, f ) ->
    R = new Proxy ( f.bind bind_target ),
      get: ( target, key ) ->
        return target[ key ] if key in [ 'bind', ] # ... other properties ...
        return target[ key ] if ( js_type_of key ) is 'symbol'
        return ( xP... ) -> target key, xP...
    R[ isa_keymethod_proxy ] = true
    return R


  #===========================================================================================================
  # SAMPLE OBJECTS WITH INSTANCE METHODS, STATIC METHODS
  #-----------------------------------------------------------------------------------------------------------
  object_with_class_properties =
    find:   ( id    ) -> info "class method 'find()'", ( k for k of @ )
    create: ( attrs ) -> info "class method 'create()'", ( k for k of @ )

  #-----------------------------------------------------------------------------------------------------------
  object_with_instance_properties =
    save: -> info "instance method 'save()'", ( k for k of @ )

    # #---------------------------------------------------------------------------------------------------------
    # isa: get_keymethod_proxy ( type, P... ) ->
    #   urge "µ1129 object #{rpr @instance_name} isa #{rpr type} called with #{rpr P}"
    #   urge "µ1129 my @specs: #{rpr @specs}"
    #   urge "µ1129 spec for type #{rpr type}: #{rpr @specs[ type ]}"

  #===========================================================================================================
  js_type_of = ( x ) -> return ( ( Object::toString.call x ).slice 8, -1 ).toLowerCase()
  isa_keymethod_proxy = Symbol 'proxy'

  #-----------------------------------------------------------------------------------------------------------
  isa = ( type, xP... ) ->
    ### NOTE realistic method should throw error when `type` not in `specs` ###
    urge "µ1129 object #{rpr @instance_name} isa #{rpr type} called with #{rpr xP}"
    urge "µ1129 my @specs: #{rpr @specs}"
    urge "µ1129 spec for type #{rpr type}: #{rpr @specs[ type ]}"

  #-----------------------------------------------------------------------------------------------------------
  class Intertype extends Multimix
    @extend   object_with_class_properties
    @include  object_with_instance_properties

    #---------------------------------------------------------------------------------------------------------
    constructor: ( @instance_name ) ->
      super()
      @specs = {}
      @declare type, value for type, value of @constructor.base_types
      @isa = _get_keymethod_proxy @, isa

    #---------------------------------------------------------------------------------------------------------
    declare: ( type, value ) ->
      whisper 'µ7474', 'declare', type, rpr value
      @specs[ type ] = value

    #---------------------------------------------------------------------------------------------------------
    @base_types =
      foo: 'spec for type foo'
      bar: 'spec for type bar'


  ############################################################################################################
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



############################################################################################################
unless module.parent?
  # raw_example()
  rewritten_example()

