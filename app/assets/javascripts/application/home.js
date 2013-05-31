Zapfolio.PAGES["home_show"] = function() {
  $(".feature .thumbnail img").click(function() {
    var modal = $("<div class='modal' id='thumbnail-feature'><img src='" + $(this).data("full") + "'></div>").modal();
  });
};