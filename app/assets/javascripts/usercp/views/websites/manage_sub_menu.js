Zapfolio.Views.Websites.ManageSubMenu = Backbone.View.extend({
  initialize: function(data) {
    this.website = data.website;
    this.pages = data.pages;
    this.menu = data.menu;
    this.subMenu = data.subMenu;

    this.mp_base = "Website -> Sub Menu -> " + (!this.subMenu.id ? "New" : "Edit");
    this.mp_track();
  },

  title: function() {
    if( this.subMenu.id ) {
      return I18n.t("usercp.titles.js.website/edit_sub_menu", {name: this.subMenu.name});
    } else {
      return I18n.t("usercp.titles.js.website/new_sub_menu", {name: this.menu.name});
    }
  },

  events: {
    "submit": "save"
  },

  render: function() {
    this.$el.html(HandlebarsTemplates["websites/manage_sub_menu"]({menu: this.menu, subMenu: this.subMenu, website: this.website.toJSON(), pages: this.pages.toJSON(), pageID: this.subMenu.page_id}));
    return this;
  },

  save: function(event) {
    event.preventDefault();
    this.$el.find("input[type='submit']").button("loading");
    this.cleanup_errors();

    this.subMenu.name = $("#website_menus_sub_menus_name").val();
    this.subMenu.page_id = $("#website_menus_sub_menus_page_id").val() == "" ? "" : $("#website_menus_sub_menus_page_id").val();

    // New sub menu
    if( !this.subMenu.id ) {
      this.subMenu.id = "1";
      this.subMenu.order = this.menu.sub_menus.length + 1;
      this.menu.sub_menus.push(this.subMenu);
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
    this.previousState = {subMenu: $.extend({}, this.subMenu)};
  },

  restoreState: function() {
    this.mp_track("Canceled");

    if( this.subMenu.id == "1" ) {
      this.website.removeSubMenu(this.menu.id, "1");
    } else {
      $.extend(this.subMenu, this.previousState.subMenu);
    }
  }
});

_.extend(Zapfolio.Views.Websites.ManageSubMenu.prototype, Zapfolio.Helpers.Errors, Zapfolio.Helpers.Mixpanel);