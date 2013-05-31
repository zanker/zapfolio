Zapfolio.ajax_warner = function() {
  var requests = [];

  function can_leave_page() {
    for( var i=0, total=requests.length; i < total; i++ ) {
      if( requests[i].readyState != 4 ) {
        return false;
      }
    }

    return true;
  }

  $(window).on("beforeunload", function() {
    if( !can_leave_page() ) {
      return I18n.t("js.ajax_leave");
    }

    if( Zapfolio.unload_confirmation ) return Zapfolio.unload_confirmation("unload");
  });

  $(document).on("click.setup", "a.js-nav, a.go-back", function(event) {
    if( !can_leave_page() && !confirm(I18n.t("js.ajax_leave")) ) {
      event.stopImmediatePropagation();
      event.preventDefault();

    // Check for a custom confirmation callback
    } else if( Zapfolio.unload_confirmation && Zapfolio.unload_confirmation("js") ) {
      event.stopImmediatePropagation();
      event.preventDefault();
    }
  });

  $("body").on("ajaxSend", function(event, xhr, request) {
    if( request.dataType == "json" ) {
      requests.push(xhr);
    }
  }).on("ajaxComplete", function(event, xhr, request) {
    if( request.dataType == "json" ) {
      requests.splice(requests.indexOf(request), 1);
    }
  });
};