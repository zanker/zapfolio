Zapfolio.Views.Websites.Show = Backbone.View.extend({
  page_id: "website/show",
  initialize: function(data) {
    this.website = data.website;
    this.pages = data.pages;
    this.user = data.user;

    this.website.bind("change", this.render, this);
    this.pages.bind("change", this.render, this);
    this.pages.bind("remove", this.render, this);

    this.mp_base = "Website";
    this.mp_track();

    if( this.user.get("flags")["intro"] ) {
      this.show_user_intro();
    }
  },

  events: {
    "click .set-home": "set_home",
    "click .edit-menu": "modal_nav",
    "click .edit-sub-menu": "modal_nav",
    "click #new-menu": "modal_nav",
    "click .add-sub-menu": "modal_nav",
    "click .remove-menu": "remove_menu",
    "click .remove-sub-menu": "remove_sub_menu",
    "click #new-page": "modal_nav",
    "click .delete-page": "delete_page",
    "click .edit-page": "modal_nav"
  },

  render: function() {
    this.$el.html(HandlebarsTemplates["websites/show"]({website: this.website.toJSON(), pages: this.pages.toJSON()}));
    this.$el.find("a[title]").tooltip({animation: false});
    return this;
  },

  modal_nav: function(event) {
    event.preventDefault();

    var target = $(event.currentTarget);
    if( !target.hasClass("disabled") ) Zapfolio.Helpers.Navigate(target);
  },

  // Show our intro model to the user
  show_user_intro: function() {
    this.mp_track("Intro");

    var about_pages = this.pages.where({type: "about"});

    var modal = $(HandlebarsTemplates["websites/intro"]({about_page_id: about_pages[0] ? about_pages[0].id : null}));
    modal.modal({keyboard: false, backdrop: "static"});
    modal.on("hide", function() {
      $("#intro").remove();
    });

    $("#intro a:not(.contact_email)").click(function() {
      modal.modal("hide");
    });

    // Unflag so this stops showing up
    var flags = this.user.get("flags");
    delete(flags.intro);
    this.user.set("flags", flags);
    $.ajax("/admin/users/unflag/intro", {type: "PUT"});
  },

  // Modal management
  remove_menu: function(event) {
    event.preventDefault();

    var target = $(event.currentTarget).closest("li.parent");
    var scope = this;

    this.mp_track(["Menu", "Delete"]);
    Zapfolio.Helpers.Confirmation("delete", function(confirm) {
      scope.website.removeMenu(target.data("menu-id"));
      scope.website.save({}, {success: function() {
        scope.mp_track(["Menu", "Delete", "Finished"]);
        confirm.modal("hide");
      }});
    }, function() {
      scope.mp_track(["Menu", "Delete", "Canceled"]);
    });
  },

  remove_sub_menu: function(event) {
    event.preventDefault();

    var target = $(event.currentTarget).closest("li");
    var scope = this;

    this.mp_track(["Sub Menu", "Delete"]);
    Zapfolio.Helpers.Confirmation("delete", function(confirm) {
      scope.website.removeSubMenu(target.closest(".parent").data("menu-id"), target.data("sub-menu-id"));
      scope.website.save({}, {success: function() {
        scope.mp_track(["Sub Menu", "Delete", "Finished"]);
        confirm.modal("hide");
      }});
    }, function() {
      scope.mp_track(["Sub Menu", "Delete", "Canceled"]);
    });
  },

  // Page management
  delete_page: function(event) {
    event.preventDefault();

    var target = $(event.currentTarget);
    var tr = target.closest("tr");
    var page = this.pages.get(tr.data("page-id"));
    var scope = this;
    var page_type = page.get("type");

    tr.find("a").tooltip("hide");

    this.mp_track(["Page", "Delete"], {page_type: page_type});
    Zapfolio.Helpers.Confirmation("delete", function(confirm) {
      tr.find("a").addClass("disabled");
      tr.find("td:first-child").text(I18n.t("usercp.websites.show.js.removing"));

      page.destroy({success: function() {
        confirm.modal("hide");
        scope.mp_track(["Page", "Delete", "Finished"], {page_type: page_type});
      }});
    }, function() {
      scope.mp_track(["Page", "Delete", "Canceled"], {page_type: page_type});
    });
  },

  set_home: function(event) {
    event.preventDefault();

    var target = $(event.currentTarget);
    target.button("loading");
    target.tooltip("hide");

    var scope = this;
    this.website.save({home_page_id: target.closest("tr").data("page-id")}, {success: function(model) {
      var page = scope.pages.get(model.attributes.home_page_id);
      scope.mp_track("Set Home", {page_type: page.get("type")});
    }});
  }
});

_.extend(Zapfolio.Views.Websites.Show.prototype, Zapfolio.Helpers.Mixpanel);