Zapfolio.Helpers.Navigate = function(a) {
  Backbone.history.navigate(a.attr("href").replace(Backbone.history.options.root, ""), {trigger: true});
};