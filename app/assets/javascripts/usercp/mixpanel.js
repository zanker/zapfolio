Zapfolio.mixpanel = function(analytics_id, user, kicker) {
  // User tags
  function update_user() {
    mixpanel.register({sub_plan: user.sub_plan()});
    mixpanel.register_once({provider: user.get("provider"), user_id: user.get("id")});
    mixpanel.name_tag(user.get("email"));

    update_people();
  }

  function update_people() {
    mixpanel.people.set({"$email": user.get("email"), "$name": user.get("full_name"), "$last_login": new Date(), "$created": user.get("created_at"), "sub_plan": user.sub_plan(), "provider": user.get("provider"), "albums": kicker.albums.length, "pages": kicker.pages.length});
  }

  user.bind("change", update_user);
  kicker.pages.bind("change", update_people);
  kicker.albums.bind("change", update_people);

  // Contact clicked
  $(".contact_email").click(function() {
    mixpanel.track("Email Contact Clicked", {location: $(this).data("location")});
  });

  // Page view tracking
  Backbone.history.bind("route", function() {
    mixpanel.track_pageview(this.options.root + this.fragment);
  });

  mixpanel.identify(analytics_id);
  mixpanel.people.identify(analytics_id);

  update_user();
};