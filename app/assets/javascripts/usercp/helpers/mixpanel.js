Zapfolio.Helpers.Mixpanel = {
  mp_track: function(name, args) {
    if( name && typeof(name) == "object" ) name = name.join(" -> ");
    name = name ? (this.mp_base + " -> " + name) : this.mp_base;

    mixpanel.track(name, args);
  }
};