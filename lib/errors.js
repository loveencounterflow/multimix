(function() {
  'use strict';
  var GUY, rpr;

  //###########################################################################################################
  GUY = require('guy');

  ({rpr} = GUY.trm);

  //-----------------------------------------------------------------------------------------------------------
  this.Multimix_error = class Multimix_error extends Error {
    constructor(ref, message) {
      super();
      if (ref === null) {
        this.message = message;
        return void 0;
      }
      this.message = `${ref} (${this.constructor.name}) ${message}`;
      this.ref = ref;
      return void 0/* always return `undefined` from constructor */;
    }

  };

  //-----------------------------------------------------------------------------------------------------------
  this.Multimix_no_such_property = class Multimix_no_such_property extends this.Multimix_error {
    constructor(ref, key) {
      super(ref, `no such property: ${rpr(key)}`);
    }

  };

  //-----------------------------------------------------------------------------------------------------------
  this.Multimix_reassignment_error = class Multimix_reassignment_error extends this.Multimix_error {
    constructor(ref, key) {
      super(ref, `oneshot object does not allow re-assignment to property ${rpr(key)}`);
    }

  };

  //-----------------------------------------------------------------------------------------------------------
  this.Multimix_deletion_error = class Multimix_deletion_error extends this.Multimix_error {
    constructor(ref, key) {
      super(ref, `object does not allow deletion of property ${rpr(key)}`);
    }

  };

  //-----------------------------------------------------------------------------------------------------------
  this.Multimix_cfg_error = class Multimix_cfg_error extends this.Multimix_error {};

}).call(this);

//# sourceMappingURL=errors.js.map