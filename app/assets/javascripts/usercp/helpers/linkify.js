Handlebars.registerHelper("linkify", function(key) {
  var text = I18n.t(key);
  var list = text.match(/{(.+?)}/g);
  for( var i=0, total=list.length; i < total; i++ ) {
    text = text.replace(list[i], "<a href='" + arguments[i + 1] + "' class='js-nav'>" + list[i].substring(1, list[i].length - 1) + "</a>");
  }

  return text;
});