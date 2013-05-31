Zapfolio.Views.Billing = {};
Zapfolio.Routers.Billing = Backbone.Router.extend({
  initialize: function(user, data) {
    this.user = user;
    this.website = data.website;
  },

  routes: {
    "billing": "show",
    "subscription": "subscriptions",
    "subscription/checkout/:plan": "checkout"
  },

  show: function() {
    this.swap(new Zapfolio.Views.Billing.Show({user: this.user}));
  },

  subscriptions: function() {
    this.swap(new Zapfolio.Views.Billing.Subscriptions({user: this.user}));
  },

  checkout: function(plan) {
    this.swap(new Zapfolio.Views.Billing.Checkout({plan: plan, user: this.user, website: this.website}));
  }
});