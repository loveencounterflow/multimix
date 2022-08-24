
'use strict'


############################################################################################################
GUY                       = require 'guy'
{ rpr   }                 = GUY.trm


#-----------------------------------------------------------------------------------------------------------
class @Multimix_error extends Error
  constructor: ( ref, message ) ->
    super()
    if ref is null
      @message  = message
      return undefined
    @message  = "#{ref} (#{@constructor.name}) #{message}"
    @ref      = ref
    return undefined ### always return `undefined` from constructor ###

#-----------------------------------------------------------------------------------------------------------
class @Multimix_no_such_property extends @Multimix_error
  constructor: ( ref, key ) -> super ref, "no such property: #{rpr key}"
