Zapfolio.Views.Websites = {};
Zapfolio.Routers.Websites = Backbone.Router.extend({
  initialize: function(user, data) {
    this.website = data.website;
    this.pages = data.pages;
    this.albums = data.albums;
    this.user = user;
  },

  routes: {
    "websites": "show",
    "websites/edit": "edit",
    "websites/layout": "layout",
    "websites/layout/css": "edit_css",
    "websites/menu": "add_menu",
    "websites/menu/reorder": "reorder_menus",
    "websites/menu/:menu_id": "edit_menu",
    "websites/menu/:menu_id/sub": "add_sub_menu",
    "websites/menu/:menu_id/:sub_menu_id": "edit_sub_menu",
    "websites/pages/type": "page_type",
    "websites/pages/new/:page_type": "add_page",
    "websites/pages/:page_id": "edit_page"
  },

  show: function() {
    this.swap(new Zapfolio.Views.Websites.Show({user: this.user, website: this.website, pages: this.pages}));
  },

  edit: function() {
    this.swap(new Zapfolio.Views.Websites.Edit({user: this.user, website: this.website}));
  },

  layout: function() {
    this.swap(new Zapfolio.Views.Websites.Layout({user: this.user, website: this.website}));
  },

  edit_css: function() {
    this.swap(new Zapfolio.Views.Websites.EditCSS({user: this.user, website: this.website}));
  },

  page_type: function() {
    this.swapModal("show", new Zapfolio.Views.Pages.Type({user: this.user}));
  },

  add_page: function(pageType) {
    this.swap(new Zapfolio.Views.Pages.Manage({user: this.user, website: this.website, albums: this.albums, pages: this.pages, page: new Zapfolio.Models.Page({type: pageType})}));
  },

  edit_page: function(pageID) {
    this.swap(new Zapfolio.Views.Pages.Manage({user: this.user, website: this.website, albums: this.albums, pages: this.pages, page: this.pages.get(pageID)}));
  },

  reorder_menus: function() {
    this.swapModal("show", new Zapfolio.Views.Websites.ReorderMenus({website: this.website}));
  },

  add_menu: function() {
    this.swapModal("show", new Zapfolio.Views.Websites.ManageMenu({website: this.website, pages: this.pages, menu: {}}));
  },

  edit_menu: function(menuID) {
    this.swapModal("show", new Zapfolio.Views.Websites.ManageMenu({website: this.website, pages: this.pages, menu: this.website.findMenu(menuID)}));
  },

  add_sub_menu: function(menuID) {
    this.swapModal("show", new Zapfolio.Views.Websites.ManageSubMenu({website: this.website, pages: this.pages, menu: this.website.findMenu(menuID), subMenu: {}}));
  },

  edit_sub_menu: function(menuID, subMenuID) {
    this.swapModal("show", new Zapfolio.Views.Websites.ManageSubMenu({website: this.website, pages: this.pages, menu: this.website.findMenu(menuID), subMenu: this.website.findSubMenu(menuID, subMenuID)}));
  }
});