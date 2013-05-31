Handlebars.registerHelper("intro_suggestion", function() {
  if( this.about_page_id ) {
    return Handlebars.helpers["linkify"]("usercp.websites.intro.js.however_suggest_edit", "/admin/websites/pages/new/mediacarousel", "/admin/websites/pages/" + this.about_page_id);
  } else {
    return Handlebars.helpers["linkify"]("usercp.websites.intro.js.however_suggest_new", "/admin/websites/pages/new/mediacarousel", "/admin/websites/pages/new/about");
  }
});