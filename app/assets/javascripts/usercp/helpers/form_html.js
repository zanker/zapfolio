Handlebars.registerHelper("page_options", function(context) {
  var html = "";
  for( var i=0, total=context.pages.length; i < total; i++ ) {
    html += "<option value='" + context.pages[i].id + "'";
    if( context.pages[i].id === context.pageID ) html += " selected='selected'";
    html += ">";
    html += context.pages[i].name;
    html += "</option>";
  }

  return html;
});

Handlebars.registerHelper("bool_to_int", function(bool) {
  return bool == true ? 1 : 0;
});

Handlebars.registerHelper("option", function(val, label, matcher, key, sub_key) {
  if( matcher ) {
    if( typeof(key) != "undefined" && matcher[key] ) matcher = matcher[key];
    if( typeof(sub_key) != "undefined" && matcher[sub_key] ) matcher = matcher[sub_key];
  }

  var selected = (val == matcher) ? " selected='selected'" : "";
  return "<option value='" + val + "'" + selected + ">" + (label.match(/\./) ? I18n.t(label) : label) + "</option>";
});

Handlebars.registerHelper("checkbox", function(name, val, matcher) {
  var checked = "";
  if( ( typeof(val) == "object" && $.inArray(matcher, val) >= 0 ) || ( typeof(val) != "object" && matcher == val ) )  {
    checked = " checked='checked'";
  }

  return "<input type='checkbox' name='" + name + "' value='" + matcher + "'" + checked + ">";
});