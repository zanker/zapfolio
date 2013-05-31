Zapfolio.Views.Users.Edit = Backbone.View.extend({
  page_id: "user/edit",

  initialize: function(data) {
    this.user = data.user;

    this.mp_base = "User -> Edit";
    this.mp_track();
  },

  events: {
    "submit": "save"
  },

  render: function() {
    this.$el.html(HandlebarsTemplates["users/edit"]({user: this.user}));
    return this;
  },

  save: function(event) {
    event.preventDefault();
    this.$el.find("input[type='submit']").button("loading");
    this.cleanup_errors();

    var scope = this;
    this.user.save({email: $("#user_email").val(), full_name: $("#user_full_name").val(), receive_emails: $("#user_receive_emails").val()}, {error: function(model, res) { scope.handle_errors(res); }, success: function() { scope.saved(); }});
    return false;
  },

  saved: function() {
    Zapfolio.Helpers.Flash("success", I18n.t("usercp.users.edit.js.settings_updated"));

    this.mp_track("Saved");

    this.committed = true;
    this.$el.find(".go-back").click();
  },

  // State management
  saveState: function() {
    this.previousState = $.extend({}, this.user.attributes);
  },

  restoreState: function() {
    this.user.attributes = this.previousState;
  }
});

_.extend(Zapfolio.Views.Users.Edit.prototype, Zapfolio.Helpers.Errors, Zapfolio.Helpers.Forms, Zapfolio.Helpers.Mixpanel);