//= require jquery
//= require libraries/airbrake.notifier
//= require bootstrap/bootstrap-alert
//= require bootstrap/bootstrap-transition
//= require bootstrap/bootstrap-dropdown
//= require bootstrap/bootstrap-tooltip
//= require bootstrap/bootstrap-tab
//= require bootstrap/bootstrap-modal
//= require_self
//= require_tree ./application/

var Zapfolio = {PAGES: {}};
Zapfolio.initialize = function() {
  $(".tt").tooltip({animation: false});
  $(".dropdown-toggle").dropdown();

  $(".contact_email").click(function() {
    mixpanel.track("Email Contact Clicked", {location: $(this).data("location")});
  });

  $("#demo-create a, .demo-create").attr("onclick", null);
  $("#demo-create a, .demo-create").click(function(event) {
    event.preventDefault();

    $("#demo-account").modal({keyboard: false, backdrop: "static"});

    $.ajax($(this).attr("href"), {
      type: "POST",
      error: function(xhr) {
        $("#demo-account").find(".settingup, .ready").addClass("hidden");
        $("#demo-account").find(".modal-body .error p").addClass("red").html(xhr.responseText);
        $("#demo-account").find(".error").removeClass("hidden");
      },
      success: function() {
        $("#demo-account").find(".settingup, .error").addClass("hidden");
        $("#demo-account").find(".ready").removeClass("hidden");
      }
    });
  });
};