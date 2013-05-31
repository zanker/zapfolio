Zapfolio.Views.Billing.Subscriptions = Backbone.View.extend({
  page_id: "billing/subscriptions",

  initialize: function(data) {
    this.user = data.user;

    this.mp_base = "Billing -> Subscriptions";
    this.mp_track();
  },

  events: {
  },

  render: function() {
    this.$el.html(HandlebarsTemplates["billing/subscriptions"]({user: this.user}));
    return this;
  },

  on_add: function() {
    this.$el.find("td[title]").tooltip({animation: false});
  }
});

_.extend(Zapfolio.Views.Billing.Subscriptions.prototype, Zapfolio.Helpers.Mixpanel);