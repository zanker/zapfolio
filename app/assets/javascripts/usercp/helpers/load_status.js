Zapfolio.Helpers.LoadStatus = {
  on_remove: function() {
    this.abort_sync = true;
  },

  load_status: function(queue) {
    if( this.abort_sync ) return;

    var scope = this;
    Backbone.sync("create", this.user, {
      url: "/admin/users/sync/status" + (queue ? "?queue=1" : ""),
      contentType: "application/json",
      data: "{}",
      error: function(res) {
        Zapfolio.Helpers.Errors.request_error(res.status);
      },
      success: function(res) {
        // Still loading, update progress
        if( res.loading === true ) {
          if( res.status == "error" ) {
            Zapfolio.Helpers.Errors.request_error("load");
            scope.$el.modal("hide");
            return;
          }

          scope.sync = res;

          if( res.status == "pending" || res.status == "queued" ) {
            // It's taking longer than it should, bail and error
            if( scope.update_count >= 500 ) {
              return Zapfolio.Helpers.Errors.request_error("toolong");
            }

            setTimeout(function() { scope.load_status(); }, 3000 + (scope.update_count * 100));
          } else {
            setTimeout(function() { scope.load_status(); }, 2000);
          }

          // Update the text
          var progress, text;
          if( res.status == "queued_albums" ) {
            progress = 2, text = I18n.t("usercp.users.popup_sync.js.queued_albums");
          } else if( res.status == "albums" ) {
            progress = 3, text = I18n.t("usercp.users.popup_sync.js.loaded_album", {album: res.album || I18n.t("usercp.users.popup_sync.js.no_title")});
          } else if( res.status == "album_metadata" ) {
            progress = 4, text = I18n.t("usercp.users.popup_sync.js.album_metadata", {album: res.album || I18n.t("usercp.users.popup_sync.js.no_title")});
          } else if( res.status == "queued_media" ) {
            progress = 5, text = I18n.t("usercp.users.popup_sync.js.queued_media");
          } else if( res.status == "starting" ) {
            progress = 6, text = I18n.t("usercp.users.popup_sync.js.media_starting");
          } else if( res.status == "photos" ) {
            progress = 7 + (86 * res.progress);
            text = I18n.t("usercp.users.popup_sync.js.media_loading", {total: res.total, loaded: res.loaded});
          } else if( res.status == "cleaning" ) {
            progress = 93 + (7 * res.progress);
            text = I18n.t("usercp.users.popup_sync.js.cleaning_up");
          }

          scope.$el.find(".progress .bar").attr("style", "width: " + progress + "%;");
          scope.$el.find(".status_text").text(text);

        // Finished, sync the data back
        } else {
          scope.albums.reset(res.albums);
          scope.user.set(res.user);
          scope.$el.modal("hide");
        }
      }
    });
  }
};