Zapfolio.Models.User = Backbone.Model.extend({
  url: "/admin/users",

  has_credit_card: function() {
    return !!this.user.attributes.stripe_card.type;
  },

  has_subscription: function() {
    return this.attributes.subscription && typeof(this.attributes.subscription) == "object";
  },

  has_plan: function(plan) {
    var sub = this.attributes.subscription;
    return sub && typeof(sub) == "object" ? sub.plan == plan : false;
  },

  sub_plan: function() {
    return this.attributes.subscription && typeof(this.attributes.subscription) == "object" ? this.attributes.subscription.plan : "free";
  },

  has_access: function(feature) {
    var sub = this.attributes.subscription;
    if( sub && typeof(sub) == "object" && Zapfolio.Subscriptions[sub.plan].features[feature] ) {
      return true;
    }

    return !!Zapfolio.Subscriptions.free.features[feature];
  },

  feature_limit: function(feature) {
    var sub = this.attributes.subscription;
    if( sub && typeof(sub) == "object" && Zapfolio.Subscriptions[sub.plan].features[feature] ) {
      return Zapfolio.Subscriptions[sub.plan].features[feature];
    }

    return Zapfolio.Subscriptions.free.features[feature];
  },

  can_upgrade_sub: function() {
    return !this.has_subscription() || this.has_plan("starter");
  },

  can_resync: function() {
    if( this.attributes.total_syncs > 0 && this.sync_reset_in() == 0 ) return true;

    return this.attributes.total_syncs < this.feature_limit("sync_lim");
  },

  sync_reset_in: function() {
    if( !this.attributes.last_sync ) return 0;

    var diff = 0, last_sync = Date.parse(this.attributes.last_sync);
    if( this.attributes.last_sync ) {
      diff = (Date.now() - last_sync) / (60 * 60 * 1000);
    }

    // It's been more than sync_hrs, so we can reset the limit
    var hour_limit = this.feature_limit("sync_hrs");
    if( diff > hour_limit ) {
      this.set({total_syncs: 0});
      return 0;
    }

    return last_sync + (hour_limit * 60 * 60 * 1000);
  },

  syncs_left: function() {
    // Figure out if the limit reset reset
    this.sync_reset_in();

    return this.feature_limit("sync_lim") - this.attributes.total_syncs;
  }
});