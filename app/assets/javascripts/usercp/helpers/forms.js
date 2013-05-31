Zapfolio.Helpers.Forms = {
  append_formdata: function(scope, defaults) {
    var formData = new FormData();

    if( defaults ) {
      for( var key in defaults ) {
        if( typeof(defaults[key]) != "object" ) {
          formData.append(key, defaults[key]);
        }
      }
    }

    this.$el.find("[name^=" + scope + "]").each(function() {
      var row = $(this);
      if( row.is(":disabled") || !row.is(":visible") ) return;

      var value;
      if( row.attr("type") == "file" ) {
        value = this.files[0];
      } else if( row.is("select") ) {
        value = row.find("option:selected").val();
      } else {
        value = row.val();
      }

      if( typeof(value) != "undefined" ) {
        if( row.is(":checkbox") && !row.is(":checked") ) return;

        formData.append(row.attr("name").replace(scope, ""), value);
      }
    });

    return formData;
  }
};
