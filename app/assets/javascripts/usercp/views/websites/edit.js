Zapfolio.Views.Websites.Edit = Backbone.View.extend({
  page_id: "website/edit",

  initialize: function(data) {
    this.website = data.website;
    this.user = data.user;

    this.website.bind("change", this.render, this);

    this.mp_base = "Website -> Edit";
    this.mp_track();
    this.browser_needs("xhr2");
  },

  events: {
    "mouseenter #preview-favicon": "preview_popover",
    "submit": "save"
  },

  render: function() {
    this.$el.html(HandlebarsTemplates["websites/edit"]({user: this.user, website: this.website.toJSON()}));
    return this;
  },

  save: function(event) {
    event.preventDefault();
    this.$el.find("input[type='submit']").button("loading");
    this.cleanup_errors();

    var scope = this;
    this.website.save({}, {contentType: false, data: this.append_formdata("website_", this.website.attributes), error: function(model, res) { scope.handle_errors(res); }, success: function() { scope.saved(); }});
    return false;
  },

  saved: function() {
    Zapfolio.Helpers.Flash("success", I18n.t("usercp.websites.edit.js.website_saved"));

    this.mp_track("Saved");

    this.committed = true;
    this.$el.find(".go-back").click();
  },

  // Popover
  preview_popover: function() {
    $("#preview-favicon").popover({animation: false, trigger: "hover", content: function() {
      return "<img src='" + $("#preview-favicon").data("url") + "'>";
    }}).popover("show");
  },

  // State management
  saveState: function() {
    this.previousState = $.extend({}, this.website.attributes);
  },

  restoreState: function() {
    this.website.attributes = this.previousState;
  }
});

_.extend(Zapfolio.Views.Websites.Edit.prototype, Zapfolio.Helpers.Errors, Zapfolio.Helpers.Forms, Zapfolio.Helpers.Requirements, Zapfolio.Helpers.Mixpanel);