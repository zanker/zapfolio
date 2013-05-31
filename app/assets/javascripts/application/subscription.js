Zapfolio.PAGES["subscriptions_show"] = function() {
  $("#sub-plans a.btn").click(function() {
    if( $(this).data("target") == "#prep_starter" ) {
      mixpanel.track("Subscriptions -> Login Box", {subscription: "starter"});
    } else {
      mixpanel.track("Subscriptions -> Login Box", {subscription: "premium"});
    }
  });

  mixpanel.track_links(".flickr-free", "Sessions -> Authorizing", {source: "Subscriptions -> Show", provider: "flickr"});
  mixpanel.track_links(".smugmug-free", "Sessions -> Authorizing", {source: "Subscriptions -> Show", provider: "smugmug"});

  mixpanel.track_links("#flickr-starter", "Subscriptions -> Flickr", {subscription: "starter", provider: "flickr"});
  mixpanel.track_links("#flickr-premium", "Subscriptions -> Flickr", {subscription: "premium", provider: "flickr"});

  mixpanel.track_links("#smugmug-starter", "Subscriptions -> Flickr", {subscription: "starter", provider: "smugmug"});
  mixpanel.track_links("#smugmug-premium", "Subscriptions -> Flickr", {subscription: "premium", provider: "smugmug"});
};