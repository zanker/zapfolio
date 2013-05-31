Zapfolio.Views.Users.Sync = Backbone.View.extend({
  page_id: "user/sync",

  initialize: function(data) {
    this.user = data.user;
    this.albums = data.albums;
    this.sync = {};
    this.update_count = 1;
    if( this.user.attributes.syncing ) this.load_status();

    this.albums.bind("change", this.render, this);
    this.user.bind("change", this.render, this);

    var scope = this;
    this.rerender_interval = function() {
      if( !scope.user.attributes.syncing ) {
        scope.render();
      } else {
        scope.selective_rerender();
      }
    };

    this.mp_base = "User -> Sync Status";
    this.mp_track();
  },

  events: {
    "click #user_request input[type='button']": "request_resync"
  },

  render: function() {
    this.$el.html(HandlebarsTemplates["users/sync"]({user: this.user, albums: this.albums}));

    if( this.update_interval ) clearInterval(this.update_interval);
    this.update_interval = setInterval(this.rerender_interval, 10000);
    return this;
  },

  selective_rerender: function() {
    $("#user_stats").html(Handlebars.helpers["build_stats"].apply(this));
    $("#user_request").html(Handlebars.helpers["request_sync"].apply(this));
  },

  // Manual trigger
  request_resync: function() {
    this.mp_track("Resync");
    this.user.set({syncing: true});
    this.load_status(true);
  }
});

_.extend(Zapfolio.Views.Users.Sync.prototype, Zapfolio.Helpers.LoadStatus, Zapfolio.Helpers.Mixpanel);