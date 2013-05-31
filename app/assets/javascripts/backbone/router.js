_.extend(Backbone.Router.prototype, {
  set_title: function(view) {
    if( typeof(view.title) == "function" ) {
      $("#site_title").text(view.title() + " " + I18n.t("usercp.titles.js.suffix"));
    } else {
      $("#site_title").text(I18n.t("usercp.titles.js." + view.page_id, {defaultValue: I18n.t("usercp.titles.js.generic")}) + " " + I18n.t("usercp.titles.js.suffix"));
    }
  },

  swap: function(view) {
    this.set_title(view);

    // Handle cleaning up from the last view
    if( Zapfolio.currentView ) {
      if( Zapfolio.currentView.on_remove ) Zapfolio.currentView.on_remove();
      Zapfolio.currentView.$el.remove();

      if( !Zapfolio.currentView.committed && Zapfolio.currentView.restoreState ) {
        Zapfolio.currentView.restoreState();
        delete(Zapfolio.currentView.previousState);
      }

      $(".tooltip:visible").hide();
    }

    // If we're already on a view, then remove any active flashes so they don't persist
    if( Zapfolio.currentView ) $("#content").find("div.alert").remove();

    Zapfolio.currentView = view;

    // Save state in case we cancel
    if( Zapfolio.currentView.saveState ) Zapfolio.currentView.saveState();

    // Might need a more dynamic control over rendering
    if( view.render_target ) {
      view.render_target(view.render().el);
    } else {
      $("#content").append(view.render().el);
    }

    // Callbacks
    if( Zapfolio.currentView.on_add ) Zapfolio.currentView.on_add();

    // Javascript flashes
    if( Zapfolio.Data.flash ) {
      $(Handlebars.partials["flash"](Zapfolio.Data.flash)).prependTo(view.$el);
      delete(Zapfolio.Data.flash);
    }

    // Figure out what tab is active
    var path = window.location.pathname;
    if( !Zapfolio.Supports.pushState ) {
      path = Backbone.history.options.root + Backbone.history.getHash();
    }

    if( Zapfolio.demo_account ) {
      Zapfolio.lock_demo_fields(view.$el);
    }

    Zapfolio.menu_scope.find("li.active").removeClass("active");
    Zapfolio.menu_scope.find("a[href='" + path + "']").parent().addClass("active");
  },

  swapModal: function(parentView, view) {
    // They've come to this modal page through the modal URL, but it wasn't AJAX magic
    // load the initial view before we popup the modal
    if( !Zapfolio.currentView ) {
      this[parentView]();
    }

    this.set_title(view);

    // Figure out what URL to go back to when they close the modal
    var finishRoute;
    for( var key in this.routes ) {
      if( this.routes[key] == parentView ) {
        finishRoute = key;
        break;
      }
    }

    // Hide the current modal
    if( Zapfolio.currentModal ) {
      Zapfolio.currentModal.transitioning = true;
      Zapfolio.currentModal.$el.modal("hide");
    }

    // Add the new one
    $("#content").append(view.render().el);

    // Restore the URL state to the old version
    if( view.saveState ) view.saveState();

    var scope = this;
    view.$el.modal(view.modalOptions).on("hide", function() {
      if( !view.committed && view.restoreState ) {
        view.restoreState();
        delete(view.previousState);
      }

      if( !view.transitioning ) {
        Backbone.history.navigate(finishRoute);
        scope.set_title(parentView);
      }

      view.$el.remove();
      delete(Zapfolio.currentModal);
    });

    Zapfolio.currentModal = view;
  }
});