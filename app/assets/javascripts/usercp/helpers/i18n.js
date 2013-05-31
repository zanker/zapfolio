Handlebars.registerHelper("i18n", function(key, options) {
  return new Handlebars.SafeString(I18n.t(key, options.hash));
});

Handlebars.registerHelper("inner_i18n", function(key, context) {
  if( !context ) {
    return I18n.t(key.fn(this));
  } else {
    return I18n.t(key, {value: I18n.t(context.fn(this))});
  }
});