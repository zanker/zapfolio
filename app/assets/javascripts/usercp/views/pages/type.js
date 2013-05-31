Zapfolio.Views.Pages.Type = Backbone.View.extend({
  page_id: "page/type",

  initialize: function(data) {
    this.user = data.user;

    this.mp_base = "Page -> Select Type";
    this.mp_track();
  },

  events: {
    "click .add-page": "select"
  },

  render: function() {
    this.$el.html(HandlebarsTemplates["pages/type"]({user: this.user}));
    return this;
  },

  select: function(event) {
    event.preventDefault();
    this.$el.modal("hide");

    Zapfolio.Helpers.Navigate($(event.currentTarget));
  },

  // Mixpanel tracking
  restoreState: function() {
    this.mp_track("Canceled");
  }
});

_.extend(Zapfolio.Views.Pages.Type.prototype, Zapfolio.Helpers.Mixpanel);