Zapfolio.Views.Dashboard = {};
Zapfolio.Routers.Dashboard = Backbone.Router.extend({
  initialize: function(user, data) {
    this.user = user;
  },

  routes: {"setup": "setup"},
  setup: function() {
    this.swap(new Zapfolio.Views.Dashboard.Setup({user: this.user}));
  }
});