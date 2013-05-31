Handlebars.registerHelper("page_partial", function(partial, context) {
  partial = "pages/types/" + partial;
  if( HandlebarsTemplates[partial] ) {
    return context.fn({partial: HandlebarsTemplates[partial](this)});
  } else {
    return "";
  }
});

Handlebars.registerHelper("if_complex_page", function(page, context) {
  if( page != "static" && page != "redirect" ) {
    return context.fn(this);
  } else if( context.inverse ) {
    return context.inverse(this);
  }
});

Handlebars.registerHelper("unless_complex_page", function(page, context) {
  if( page == "static" || page == "redirect" ) {
    return context.fn(this);
  } else if( context.inverse ) {
    return context.inverse(this);
  }
});

Handlebars.registerHelper("website_name", function(i18n) {
  return I18n.t(i18n, {website: this.website.full_url});
});