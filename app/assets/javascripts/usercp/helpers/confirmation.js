Zapfolio.Helpers.Confirmation = function(type, confirmed, canceled) {
  var modal = $(HandlebarsTemplates["generic/confirmation"]({type: type}));
  modal.find(".btn-danger").attr("value", I18n.t("usercp.generic.confirmation.js." + type + ".button"));

  modal.modal();
  modal.find(".btn-danger").click(function() {
    $(this).data("loading-text", I18n.t("usercp.generic.confirmation.js." + type + ".loading"));
    $(this).button("loading");
    confirmed(modal);
  });

  modal.find(".btn[data-dismiss]").click(function() {
    if( canceled ) canceled(modal);
  });
};