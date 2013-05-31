Handlebars.registerHelper("if_match", function(a, b, context) {
  if( a == b ) {
    return context.fn ? context.fn(this) : true;
  } else {
    return context.inverse ? context.inverse(this) : false;
  }
});

Handlebars.registerHelper("if_exact_match", function(a, b, context) {
  if( a === b ) {
    return context.fn ? context.fn(this) : true;
  } else {
    return context.inverse ? context.inverse(this) : false;
  }
});

Handlebars.registerHelper("unless_match", function(a, b, context) {
  if( a != b ) {
    return context.fn ? context.fn(this) : true;
  } else {
    return context.inverse ? context.inverse(this) : false;
  }
});

Handlebars.registerHelper("or", function(a, b) {
  return a || b;
});

Handlebars.registerHelper("unless_or", function(a, b, context) {
  if( !a || !b ) {
    return context.fn(this);
  }
});

Handlebars.registerHelper("if_empty", function(list, context) {
  if( list.length == 0 ) {
    return context.fn(this);
  } else if( context.inverse ) {
    return context.inverse(this);
  }
});

Handlebars.registerHelper("scoped_if", function(object, func, context) {
  if( object[func].apply(object) ) {
    return context.fn(this);
  } else if( context.inverse ) {
    return context.inverse(this);
  }
});

Handlebars.registerHelper("scoped_unless", function(object, func, context) {
  if( !object[func].apply(object) ) {
    return context.fn(this);
  } else if( context.inverse ) {
    return context.inverse(this);
  }
});