Handlebars.registerHelper("has_access", function(feature, context) {
  if( this.user.has_access(feature) ) {
    return context.fn(this);
  } else if( context.inverse ) {
    return context.inverse(this);
  }
});

Handlebars.registerHelper("unless_has_access", function(feature, context) {
  if( !this.user.has_access(feature) ) {
    return context.fn(this);
  } else if( context.inverse ) {
    return context.inverse(this);
  }
});

Handlebars.registerHelper("has_plan", function(plan, context) {
  if( this.user.has_plan(plan) ) {
    return context.fn(this);
  } else {
    return context.inverse(this);
  }
});

Handlebars.registerHelper("unless_has_plan", function(plan, context) {
  if( !this.user.has_plan(plan) ) {
    return context.fn(this);
  } else {
    return context.inverse(this);
  }
});