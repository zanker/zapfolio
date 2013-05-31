Zapfolio.PAGES["sessions_new"] = function() {
  $("#login .nav-tabs a").each(function() {
    var provider = $(this).attr("href").replace(/#/, "");
    mixpanel.track_links("#login-" + provider, "Sessions -> Authorizing", {source: "Sessions -> New", provider: provider});
  });

  $("#login .nav-tabs a").click(function(event) {
    $(this).tab("show");
  });

  if( location.hash ) {
    $("#login .nav-tabs a[href='" + location.hash + "']").tab("show");
  }
};