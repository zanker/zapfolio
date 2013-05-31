Zapfolio.Models.Website = Backbone.Model.extend({
  url: "/admin/websites",

  findMenu: function(menuID) {
    for( var i=0, total=this.attributes.menus.length; i < total; i++ ) {
      if( this.attributes.menus[i].id == menuID ) {
        return this.attributes.menus[i];
      }
    }
  },

  removeMenu: function(menuID) {
    for( var i=0, total=this.attributes.menus.length; i < total; i++ ) {
      if( this.attributes.menus[i].id == menuID ) {
        this.attributes.menus.splice(i, 1);
        return;
      }
    }
  },

  findSubMenu: function(menuID, subMenuID) {
    for( var i=0, total=this.attributes.menus.length; i < total; i++ ) {
      if( this.attributes.menus[i].id == menuID ) {
        var sub_menus = this.attributes.menus[i].sub_menus;
        for( var j=0, sub_total=sub_menus.length; j < sub_total; j++ ) {
          if( sub_menus[j].id == subMenuID ) return sub_menus[j];
        }

        break;
      }
    }
  },

  removeSubMenu: function(menuID, subMenuID) {
    var menu = this.findMenu(menuID);
    for( var i=0, total=menu.sub_menus.length; i < total; i++ ) {
      if( menu.sub_menus[i].id == subMenuID ) {
        menu.sub_menus.splice(i, 1);
        return;
      }
    }
  }
});