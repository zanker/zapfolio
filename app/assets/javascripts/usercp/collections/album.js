Zapfolio.Collections.Album = Backbone.Collection.extend({
  model: Zapfolio.Models.Album,

  sum_media: function() {
    var total = 0;
    this.each(function(album) {
      total += album.attributes.cnt_photos;
      total += album.attributes.cnt_videos;
    });

    return total;
  },

  latest_time: function(key) {
    var time;
    this.each(function(album) {
      if( !album.attributes[key] ) return;

      if( !time || time < album.attributes[key] ) {
        time = album.attributes[key];
      }
    });

    return time;
  }
});