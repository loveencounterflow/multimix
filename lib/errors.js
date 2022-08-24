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

}).call(this);

//# sourceMappingURL=errors.js.map