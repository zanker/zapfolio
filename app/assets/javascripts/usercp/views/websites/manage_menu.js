Zapfolio.Views.Websites.ManageMenu = Backbone.View.extend({
  initialize: function(data) {
    this.website = data.website;
    this.pages = data.pages;
    this.menu = data.menu;

    this.mp_base ="Website -> Menu -> " + (!this.menu.id ? "New" : "Edit");
    this.mp_track();
  },

  title: function() {
    if( this.menu.id ) {
      return I18n.t("usercp.titles.js.website/edit_menu", {name: this.menu.name});
    } else {
      return I18n.t("usercp.titles.js.website/new_menu");
    }
  },

  events: {
    "submit": "save"
  },

  render: function() {
    this.$el.html(HandlebarsTemplates["websites/manage_menu"]({menu: this.menu, website: this.website.toJSON(), pages: this.pages.toJSON(), pageID: this.menu.page_id}));
    return this;
  },

  save: function(event) {
    event.preventDefault();
    this.$el.find("input[type='submit']").button("loading");
    this.cleanup_errors();

    this.menu.name = $("#website_menus_name").val();
    this.menu.opened = $("#website_menus_opened").val();
    this.menu.page_id = $("#website_menus_page_id").val() == "" ? "" : $("#website_menus_page_id").val();

    // New menu
    if( !this.menu.id ) {
      this.menu.id = "1";
      this.menu.order = this.website.attributes.menus.length + 1;
      this.website.attributes.menus.push(this.menu);
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
    this.previousState = {menu: $.extend({}, this.menu)};
  },

  restoreState: function() {
    this.mp_track("Canceled");

    if( this.menu.id == "1" ) {
      this.website.removeMenu("1");
    } else {
      $.extend(this.menu, this.previousState.menu);
    }
  }
});

_.extend(Zapfolio.Views.Websites.ManageMenu.prototype, Zapfolio.Helpers.Errors, Zapfolio.Helpers.Mixpanel);
