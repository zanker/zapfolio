Zapfolio.Views.Users.PopupSync = Backbone.View.extend({
  initialize: function(data) {
    this.user = data.user;
    this.albums = data.albums;
    this.sync = {pending: true};
    this.update_count = 1;
    this.load_status();

    this.mp_base = "User -> Popup Sync";
    this.mp_track();
  },

  render: function() {
    this.$el.html(HandlebarsTemplates["users/popup_sync"]({sync: this.sync}));
    return this;
  }
});

_.extend(Zapfolio.Views.Users.PopupSync.prototype, Zapfolio.Helpers.LoadStatus, Zapfolio.Helpers.Mixpanel);
