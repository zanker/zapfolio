Zapfolio.Views.Users = {};
Zapfolio.Routers.Users = Backbone.Router.extend({
  initialize: function(user, data) {
    this.user = user;
    this.albums = data.albums;
  },

  routes: {
    "users/edit": "edit",
    "users/sync": "sync"
  },

  edit: function() {
    this.swap(new Zapfolio.Views.Users.Edit({user: this.user}));
  },

  sync: function() {
    this.swap(new Zapfolio.Views.Users.Sync({user: this.user, albums: this.albums}));
  }
});