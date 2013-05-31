Zapfolio.Views.Websites.ReorderMenus = Backbone.View.extend({
  page_id: "website/reorder_menus",
  initialize: function(data) {
    this.website = data.website;

    this.mp_base = "Website -> Reorder Menus";
    this.mp_track();
  },

  events: {
    "submit": "save"
  },

  render: function() {
    this.$el.html(HandlebarsTemplates["websites/reorder_menus"]({website: this.website.toJSON()}));
    this.$el.find(".parents, .children").dragsort({placeHolderTemplate: "<li class='placeholder'>&nbsp;</li>"});

    var scope = this.$el.find(".modal-body");
    this.$el.on("show", function() { scope.css({height: scope.height() + "px"}); });

    return this;
  },

  save: function(event) {
    event.preventDefault();
    this.$el.find("input[type='submit']").button("loading");
    this.cleanup_errors();

    // Convert the li ordering into numeric ones we can save
    var menu_orders = {}, order = 0;
    this.$el.find("li.parent").each(function() { menu_orders[$(this).data("menu-id")] = [order, $(this)]; order++ });

    // Reorganize menus
    for( var i=0, total=this.website.attributes.menus.length; i < total; i++ ) {
      var menu = this.website.attributes.menus[i];
      menu.order = menu_orders[menu.id][0];

      if( menu.sub_menus.length == 0 ) continue;

      // Reorganize sub menus
      order = 0;
      var sub_menus = {};
      menu_orders[menu.id][1].find("li.child").each(function() { sub_menus[$(this).data("sub-menu-id")] = order; order++ });

      for( var j=0, sub_total=menu.sub_menus.length; j < sub_total; j++ ) {
        menu.sub_menus[j].order = sub_menus[menu.sub_menus[j].id];
      }
    }

    var scope = this;
    this.website.save({}, {error: function(model, res) { scope.handle_errors(res); }, success: function() { scope.saved(); }});

    return false;
  },

  saved: function() {
    this.mp_track("Saved");

    this.committed = true;
    this.$el.modal("hide");
  },

  // Handle restoring state if we cancel
  saveState: function() {
    this.previousState = [];
    for( var i=0,total=this.website.attributes.menus.length; i < total; i++ ) {
      this.previousState.push(this.website.attributes.menus[i]);
    }
  },

  restoreState: function() {
    this.website.attributes.menus = this.previousState;

    this.mp_track("Canceled");
  }
});

_.extend(Zapfolio.Views.Websites.ReorderMenus.prototype, Zapfolio.Helpers.Errors, Zapfolio.Helpers.Mixpanel);