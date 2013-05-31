Zapfolio.Helpers.Requirements = {
  browser_needs: function(feature) {
    var missing;
    if( feature == "xhr2" ) {
      missing = window.FormData === undefined;
    }

    if( missing ) {
      $("div.alert").remove();
      $(Handlebars.partials["flash"]({type: "alert", msg: I18n.t("js.requirements." + feature)})).prependTo($("#content"));
    }
  }
};