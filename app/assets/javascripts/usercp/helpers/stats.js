Handlebars.registerHelper("build_stats", function() {
  var html = "";
  html += "<li><i class='icon-black icon-folder-close top'></i> " + I18n.p(this.albums.length, "usercp.users.sync.js.total_albums", {wrap: "strong"}) + "</li>";
  html += "<li><i class='icon-black icon-file top'></i> " + I18n.p(this.albums.sum_media(), "usercp.users.sync.js.total_media", {wrap: "strong"}) + "</li>";

  var time = Date.parse(this.albums.latest_time("prov_updated"));
  html += "<li><i class='icon-black icon-picture top'></i> " + I18n.t("usercp.users.sync.js.last_updated", {time: (time ? "<strong>" + I18n.r("date.formats.long", time) + "</strong>" : "---"), provider: I18n.t("js.providers." + this.user.attributes.provider)}) + "</li>";

  time = Date.parse(this.user.attributes.last_sync);
  html += "<li><i class='icon-black icon-time top'></i> " + I18n.t("usercp.users.sync.js.last_sync", {time: (time ? "<strong>" + I18n.r("date.formats.long", time) + "</strong>" : "---")}) + "</li>";

  time = Date.parse(this.user.attributes.next_sync);
  html += "<li><i class='icon-black icon-refresh top'></i> " + I18n.t("usercp.users.sync.js.next_sync", {time: (time ? "<strong>" + I18n.r("date.formats.long", time) + "</strong>" : "---")}) + "</li>";

  return "<ul class='unstyled simple'>" + html + "</ul>";
});

Handlebars.registerHelper("request_sync", function() {
  if( !this.user.can_resync() ) {
    return "<p class='red last'>" + I18n.t("usercp.users.sync.js.resyncs_used", {limit: this.user.feature_limit("sync_lim"), time: I18n.r("date.formats.long", this.user.sync_reset_in())}) + "</p>";
  } else if( Zapfolio.demo_account ) {
    return "<p class='red last'>" + I18n.t("js.demo.do_restriction") + "</p>";
  }

  var html;

  var sync_reset = this.user.sync_reset_in();
  if( sync_reset > 0 ) {
    html = "<p>" + I18n.p(this.user.syncs_left(), "usercp.users.sync.js.sync_info_timer", {wrap: "strong", time: "<strong>" + I18n.r("date.formats.long", this.user.sync_reset_in()) + "</strong>"}) + "</p>";
  } else {
    html = "<p>" + I18n.p(this.user.syncs_left(), "usercp.users.sync.js.sync_info", {wrap: "strong", hours: "<strong>" + I18n.p(this.user.feature_limit("sync_hrs"), "js.hours") + "</strong>"}) + "</p>";
  }

  if( !this.user.attributes.syncing ) {
    html += "<input type='button' value='" + I18n.t("usercp.users.sync.js.request_sync") + "' class='btn btn-small'>";
  } else {
    html += "<input type='button' value='" + I18n.t("usercp.users.sync.js.sync_pending") + "' class='btn btn-small' disabled='disabled'>";
  }

  return html;
});