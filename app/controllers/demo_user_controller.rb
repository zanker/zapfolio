class DemoUserController < ApplicationController
  before_filter :require_logged_out

  def create
    # Reduce the chance of someone abusing this and creating a lot of demo accounts
    if User.where(:current_sign_in_ip => request.ip, :demo_expires.exists => true).exists?
      if request.post?
        return render :text => t("page_errors.demo_throttle", :email => view_context.mail_to(CONFIG[:contact][:email])), :status => :bad_request
      else
        return redirect_to new_session_path, :alert => t("page_errors.demo_throttle", :email => CONFIG[:contact][:email]), :flash => {:email => "1"}
      end
    end

    rand_id = rand(1..999999)
    rand_id = 0 if Rails.env.development?

    # Demo account
    user = User.new
    user.provider = "flickr"
    user.username = "demo"
    user.email = "null+#{rand_id}@zapfol.io"
    user.remember_token = SecureRandom.base64(60).tr("+/=", "pqr")
    user.build_subscription(:plan => "premium")
    user.full_name = "John Doe"
    user.demo_expires = Time.now.utc + CONFIG[:demo_length]
    user.current_sign_in_at = Time.now.utc
    user.current_sign_in_ip = request.ip

    # Move over the analytics id into the user model too
    if cookies.signed[:aid]
      user.analytics_id = cookies.signed[:aid]
    end

    user.save(:validate => false)

    loremipsum = <<TEXT
<b>Lorem ipsum dolor sit amet, consectetur adipiscing elit.</b> <i>Pellentesque rutrum tempus feugiat.</i> Ut luctus, sapien vel accumsan adipiscing, justo turpis tempus leo, et euismod ante felis rhoncus felis. Praesent nec pharetra eros. In a ipsum aliquam arcu dictum consequat. Curabitur sed risus sed elit tincidunt cursus non in nisl. Nam non mi elementum est commodo dapibus id sit amet leo. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Mauris eu nisl lobortis velit dignissim vestibulum gravida in lacus. In quis nulla a ipsum posuere feugiat.

<i>Vivamus condimentum dapibus quam, sit amet ultrices arcu pulvinar vitae.</i> Donec tristique semper erat, non ullamcorper magna egestas id. Suspendisse a augue vitae justo bibendum elementum. Aliquam mollis elementum pellentesque. Mauris volutpat egestas lorem eu ultricies. Fusce in varius risus. Quisque vitae metus purus. Vestibulum at lobortis mi. Etiam sodales augue quis urna pharetra at commodo diam imperdiet. Cras auctor mi a nulla accumsan tristique.

<b>Etiam elementum dolor sit amet est sollicitudin ut ultrices justo hendrerit.</b> Suspendisse risus quam, tristique cursus dignissim ut, fermentum eget dolor. Vestibulum placerat accumsan tempor. Donec consectetur ornare lacus, a auctor lorem facilisis at. Pellentesque faucibus, lacus eget egestas euismod, libero dui elementum felis, at accumsan sapien nunc eget justo. Mauris non lacinia sapien. Ut adipiscing rutrum dolor vel auctor. Proin at felis sed tellus volutpat convallis. Fusce tempus, diam sit amet pharetra tempor, tellus neque tempus justo, ut commodo est ligula quis sapien. Phasellus posuere venenatis interdum. Cras pulvinar euismod enim, id posuere risus semper at. Vivamus et velit ut nisl euismod sagittis. Fusce pretium aliquam ipsum ut pulvinar. Sed sed orci lectus. Etiam rhoncus orci sed sem tristique consectetur.

Aenean sed turpis eros. Vivamus lectus turpis, volutpat sollicitudin molestie sed, tincidunt eget neque. Phasellus vitae orci lacus. Maecenas id augue dui. Nam sollicitudin mollis mi, nec viverra lorem rhoncus in. Vestibulum ultricies placerat molestie. Nullam facilisis arcu vel nunc posuere mattis. Phasellus sed augue enim, vitae euismod ipsum. Nam id tortor sem. Duis at elit massa, ut auctor mi. Etiam pretium lorem suscipit mauris dapibus sed consequat elit blandit. Nam ullamcorper ultricies quam, at lacinia justo lacinia eu. Nunc interdum, tellus at mollis accumsan, augue massa rutrum leo, a adipiscing nibh dui sit amet augue. Proin ligula elit, pharetra sit amet luctus nec, fermentum pulvinar massa.

Nullam aliquet sodales adipiscing. In egestas dui eget magna iaculis vel interdum augue auctor. Morbi imperdiet, risus nec vestibulum semper, erat elit rhoncus nibh, vel luctus metus ante sagittis tortor. Etiam pharetra, libero non tincidunt elementum, dolor nulla egestas nunc, at interdum lacus quam ac magna. Vestibulum elit mi, pellentesque id facilisis vitae, viverra eu leo. Aliquam magna velit, vestibulum in volutpat id, fermentum non tellus. Suspendisse eu mattis est. Nunc vulputate, eros non fermentum vulputate, purus tellus lobortis tortor, ac fringilla dolor libero id metus. Phasellus consectetur, lectus quis ornare mattis, erat enim mattis ipsum, viverra ullamcorper tellus mauris non nunc. Nulla imperdiet accumsan sollicitudin.
TEXT

    # Albums
    album_map = {}

    albums = <<JSON
[{"_id":"502810444970cf702b000002","title":"Woods","privacy":0,"provider_id":"72157630167191494","provider":"flickr","cnt_photos":10,"cnt_videos":0,"prov_created":"2012-06-17T22:36:29Z","prov_updated":"2012-08-21T03:27:22Z","prov_info":{"primary":7389748618,"secret":"5222e82b02","server":7088,"farm":8},"created_at":"2012-08-12T20:21:24Z","updated_at":"2012-08-21T03:53:06Z"},
{"_id":"502810444970cf702b000003","title":"Misc Outdoors","description":"Mix of public and private photos.","privacy":2,"provider_id":"72157630167183922","provider":"flickr","cnt_photos":15,"cnt_videos":0,"prov_created":"2012-06-17T22:35:51Z","prov_updated":"2012-08-21T03:28:07Z","prov_info":{"primary":7389748852,"secret":"fa5861799d","server":5192,"farm":6},"created_at":"2012-08-12T20:21:24Z","updated_at":"2012-08-21T03:53:06Z"},
{"_id":"502810444970cf702b000004","title":"Foggy Plains","description":"Private Fog photos, you shouldn't see these.","privacy":1,"provider_id":"72157630167171866","provider":"flickr","cnt_photos":7,"cnt_videos":0,"prov_created":"2012-06-17T22:34:50Z","prov_updated":"2012-08-21T03:26:06Z","prov_info":{"primary":7389749284,"secret":"07d88a8db0","server":7239,"farm":8},"created_at":"2012-08-12T20:21:24Z","updated_at":"2012-08-21T03:53:06Z"}]
JSON

    JSON.parse(albums).each do |data|
      album = Album.new(data)
      album._id = BSON::ObjectId.new
      album.user = user
      album.save(:validate => false)

      album_map[data["_id"]] = album._id
    end

    # Media
    media = <<JSON
[{"title":"Canyon","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"12a727b04d","server":7217,"farm":8},"pub_flag":1,"privacy":1,"height":768,"width":1024,"prov_created":"2012-06-17T22:33:15Z","prov_updated":"2012-07-29T20:10:46Z","album_ids":["502810444970cf702b000003"],"type":0,"provider_id":"7389746612","provider":"flickr","created_at":"2012-08-12T20:21:25Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Fog 1","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"d7a9b741f7","server":7104,"farm":8},"pub_flag":1,"privacy":1,"height":1024,"width":768,"prov_created":"2012-06-17T22:33:14Z","prov_updated":"2012-06-17T22:38:15Z","album_ids":["502810444970cf702b000004"],"type":0,"provider_id":"7389749738","provider":"flickr","created_at":"2012-08-12T20:21:25Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Fog 2","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"13f03bc1d3","server":7079,"farm":8},"pub_flag":1,"privacy":1,"height":768,"width":1024,"prov_created":"2012-06-17T22:33:14Z","prov_updated":"2012-06-17T22:38:15Z","album_ids":["502810444970cf702b000004"],"type":0,"provider_id":"7389749622","provider":"flickr","created_at":"2012-08-12T20:21:25Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Fields","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"cfbfe3bc62","server":7211,"farm":8},"pub_flag":1,"privacy":0,"height":768,"width":1024,"prov_created":"2012-06-17T22:33:14Z","prov_updated":"2012-06-17T22:33:18Z","album_ids":["502810444970cf702b000003"],"type":0,"provider_id":"7389749512","provider":"flickr","created_at":"2012-08-12T20:21:24Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Fog + Fields 1","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"9028e1ec02","server":7092,"farm":8},"pub_flag":1,"privacy":0,"height":768,"width":1024,"prov_created":"2012-06-17T22:33:14Z","prov_updated":"2012-06-17T22:33:18Z","album_ids":["502810444970cf702b000003"],"type":0,"provider_id":"7389749396","provider":"flickr","created_at":"2012-08-12T20:21:24Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Fog + Fields 2","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"07d88a8db0","server":7239,"farm":8},"pub_flag":1,"privacy":1,"height":768,"width":1024,"prov_created":"2012-06-17T22:33:14Z","prov_updated":"2012-06-17T22:38:16Z","album_ids":["502810444970cf702b000003","502810444970cf702b000004"],"type":0,"provider_id":"7389749284","provider":"flickr","created_at":"2012-08-12T20:21:25Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Hills + Fog 1","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"ca853890d6","server":5324,"farm":6},"pub_flag":1,"privacy":1,"height":768,"width":1024,"prov_created":"2012-06-17T22:33:14Z","prov_updated":"2012-06-17T22:38:16Z","album_ids":["502810444970cf702b000004"],"type":0,"provider_id":"7389749216","provider":"flickr","created_at":"2012-08-12T20:21:25Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Hills + Fog 2","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"9f469630fb","server":7231,"farm":8},"pub_flag":1,"privacy":1,"height":768,"width":1024,"prov_created":"2012-06-17T22:33:14Z","prov_updated":"2012-06-17T22:38:16Z","album_ids":["502810444970cf702b000004"],"type":0,"provider_id":"7389749014","provider":"flickr","created_at":"2012-08-12T20:21:25Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Stairs 1","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"028ec6e26c","server":7226,"farm":8},"pub_flag":1,"privacy":0,"height":1024,"width":682,"prov_created":"2012-06-17T22:33:13Z","prov_updated":"2012-06-17T22:33:19Z","album_ids":["502810444970cf702b000003"],"type":0,"provider_id":"7389749166","provider":"flickr","created_at":"2012-08-12T20:21:25Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Stairs 2","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"eac44905a3","server":7095,"farm":8},"pub_flag":1,"privacy":0,"height":682,"width":1024,"prov_created":"2012-06-17T22:33:13Z","prov_updated":"2012-06-17T22:33:19Z","album_ids":["502810444970cf702b000003"],"type":0,"provider_id":"7389748954","provider":"flickr","created_at":"2012-08-12T20:21:25Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Grass 1","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"ff073724e2","server":5231,"farm":6},"pub_flag":1,"privacy":0,"height":768,"width":1024,"prov_created":"2012-06-17T22:33:13Z","prov_updated":"2012-06-17T22:33:23Z","album_ids":["502810444970cf702b000003"],"type":0,"provider_id":"7389746730","provider":"flickr","created_at":"2012-08-12T20:21:24Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Flowers","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"fa5861799d","server":5192,"farm":6},"pub_flag":1,"privacy":0,"height":682,"width":1024,"prov_created":"2012-06-17T22:33:12Z","prov_updated":"2012-06-17T22:33:19Z","album_ids":["502810444970cf702b000003"],"type":0,"provider_id":"7389748852","provider":"flickr","created_at":"2012-08-12T20:21:25Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Fog + Sea 1","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"0d6d2a0d36","server":7082,"farm":8},"pub_flag":1,"privacy":1,"height":768,"width":1024,"prov_created":"2012-06-17T22:33:12Z","prov_updated":"2012-06-17T22:38:14Z","album_ids":["502810444970cf702b000004"],"type":0,"provider_id":"7389748766","provider":"flickr","created_at":"2012-08-12T20:21:25Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Fog + Tree","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"5222e82b02","server":7088,"farm":8},"pub_flag":1,"privacy":0,"height":1024,"width":768,"prov_created":"2012-06-17T22:33:12Z","prov_updated":"2012-06-17T22:33:19Z","album_ids":["502810444970cf702b000002"],"type":0,"provider_id":"7389748618","provider":"flickr","created_at":"2012-08-12T20:21:24Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Water + Fog","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"8e22e13c3d","server":5441,"farm":6},"pub_flag":1,"privacy":1,"height":768,"width":1024,"prov_created":"2012-06-17T22:33:11Z","prov_updated":"2012-06-17T22:38:15Z","album_ids":["502810444970cf702b000003","502810444970cf702b000004"],"type":0,"provider_id":"7389748702","provider":"flickr","created_at":"2012-08-12T20:21:24Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Tea Garden","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"c8c5a309be","server":7081,"farm":8},"pub_flag":1,"privacy":0,"height":1024,"width":767,"prov_created":"2012-06-17T22:33:11Z","prov_updated":"2012-06-17T22:33:19Z","album_ids":["502810444970cf702b000003"],"type":0,"provider_id":"7389748520","provider":"flickr","created_at":"2012-08-12T20:21:25Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Trees","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"dfaaf2006d","server":8164,"farm":9},"pub_flag":1,"privacy":0,"height":1023,"width":768,"prov_created":"2012-06-17T22:33:11Z","prov_updated":"2012-06-17T22:33:19Z","album_ids":["502810444970cf702b000002"],"type":0,"provider_id":"7389746836","provider":"flickr","created_at":"2012-08-12T20:21:24Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Canyons","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"e4e6b611f5","server":5276,"farm":6},"pub_flag":1,"privacy":0,"height":768,"width":1024,"prov_created":"2012-06-17T22:33:10Z","prov_updated":"2012-06-17T22:33:20Z","album_ids":["502810444970cf702b000002"],"type":0,"provider_id":"7389748426","provider":"flickr","created_at":"2012-08-12T20:21:24Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Old Trees","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"79c4d520b4","server":5151,"farm":6},"pub_flag":1,"privacy":0,"height":768,"width":1024,"prov_created":"2012-06-17T22:33:10Z","prov_updated":"2012-06-17T22:33:19Z","album_ids":["502810444970cf702b000002"],"type":0,"provider_id":"7389748332","provider":"flickr","created_at":"2012-08-12T20:21:24Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Plants","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"ca6eecdf50","server":7088,"farm":8},"pub_flag":1,"privacy":0,"height":768,"width":1024,"prov_created":"2012-06-17T22:33:10Z","prov_updated":"2012-06-17T22:33:19Z","album_ids":["502810444970cf702b000002"],"type":0,"provider_id":"7389746914","provider":"flickr","created_at":"2012-08-12T20:21:24Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Fog 3","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"b822b97361","server":7097,"farm":8},"pub_flag":1,"privacy":0,"height":600,"width":800,"prov_created":"2012-06-17T22:33:09Z","prov_updated":"2012-06-17T22:33:19Z","album_ids":["502810444970cf702b000002"],"type":0,"provider_id":"7389748192","provider":"flickr","created_at":"2012-08-12T20:21:24Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Snowy Field","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"e2ca30e0bd","server":7104,"farm":8},"pub_flag":1,"privacy":0,"height":1024,"width":768,"prov_created":"2012-06-17T22:33:09Z","prov_updated":"2012-06-17T22:33:19Z","album_ids":["502810444970cf702b000002"],"type":0,"provider_id":"7389748076","provider":"flickr","created_at":"2012-08-12T20:21:24Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Woodland Path","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"85acd62e67","server":5151,"farm":6},"pub_flag":1,"privacy":0,"height":1024,"width":768,"prov_created":"2012-06-17T22:33:09Z","prov_updated":"2012-06-17T22:33:19Z","album_ids":["502810444970cf702b000002"],"type":0,"provider_id":"7389748012","provider":"flickr","created_at":"2012-08-12T20:21:24Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Forest Path","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"1a1a5cd7c3","server":7220,"farm":8},"pub_flag":1,"privacy":0,"height":768,"width":1024,"prov_created":"2012-06-17T22:33:09Z","prov_updated":"2012-06-17T22:33:19Z","album_ids":["502810444970cf702b000002"],"type":0,"provider_id":"7389747022","provider":"flickr","created_at":"2012-08-12T20:21:24Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Bench","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"2e08d2f591","server":7087,"farm":8},"pub_flag":1,"privacy":0,"height":768,"width":1024,"prov_created":"2012-06-17T22:33:08Z","prov_updated":"2012-06-17T22:33:19Z","album_ids":["502810444970cf702b000003"],"type":0,"provider_id":"7389747664","provider":"flickr","created_at":"2012-08-12T20:21:25Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Flowers 2","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"08152258f0","server":7221,"farm":8},"pub_flag":1,"privacy":0,"height":1024,"width":768,"prov_created":"2012-06-17T22:33:08Z","prov_updated":"2012-06-17T22:33:19Z","album_ids":["502810444970cf702b000003"],"type":0,"provider_id":"7389747554","provider":"flickr","created_at":"2012-08-12T20:21:25Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Flowers 3","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"9dc3445c21","server":8010,"farm":9},"pub_flag":1,"privacy":0,"height":768,"width":1024,"prov_created":"2012-06-17T22:33:08Z","prov_updated":"2012-06-17T22:33:19Z","album_ids":["502810444970cf702b000002"],"type":0,"provider_id":"7389747494","provider":"flickr","created_at":"2012-08-12T20:21:24Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Sea","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"a54bf3e827","server":8004,"farm":9},"pub_flag":1,"privacy":0,"height":768,"width":1024,"prov_created":"2012-06-17T22:33:08Z","prov_updated":"2012-06-17T22:33:19Z","album_ids":["502810444970cf702b000003"],"type":0,"provider_id":"7389747396","provider":"flickr","created_at":"2012-08-12T20:21:24Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Building","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"9d625feeb8","server":7212,"farm":8},"pub_flag":1,"privacy":0,"height":1024,"width":767,"prov_created":"2012-06-17T22:33:08Z","prov_updated":"2012-06-17T22:33:19Z","album_ids":["502810444970cf702b000003"],"type":0,"provider_id":"7389747158","provider":"flickr","created_at":"2012-08-12T20:21:27Z","updated_at":"2012-08-21T03:53:09Z"},
{"title":"Field 2","description":"<a href='http://www.public-domain-image.com' rel='nofollow'>www.public-domain-image.com</a>","prov_info":{"secret":"d88d68178f","server":5454,"farm":6},"pub_flag":1,"privacy":0,"height":682,"width":1024,"prov_created":"2012-06-17T22:33:07Z","prov_updated":"2012-06-17T22:33:19Z","album_ids":["502810444970cf702b000003"],"type":0,"provider_id":"7389747332","provider":"flickr","created_at":"2012-08-12T20:21:24Z","updated_at":"2012-08-21T03:53:09Z"}]
JSON

    JSON.parse(media).each do |data|
      media = Media.new(data)
      media.user = user

      album_ids = []
      media.album_ids.each do |album_id|
        album_ids.push(album_map[album_id])
      end

      media.album_ids = album_ids.uniq
      media.save(:validate => false)
    end

    # Website
    website = Website.new(:user => user)
    website.logo_uid = "demo/logo.png"
    website.subdomain = "demo-#{rand_id}"
    website.site_align = Website::LEFT
    website.menu_align = Website::LEFT
    website.name = "Demo #{rand_id}"
    website.demo = true
    website.save(:validate => false)

    # About page
    page = AboutPage.new(:website => website, :user => user)
    page.picture_uid = "demo/headshot.png"
    page.name = "About Me"
    page.title = "About"
    page.slug = "about"
    page.pic_side = AboutPage::RIGHT
    page.status = Page::PUBLIC
    page.body = loremipsum.split("\n").join("<br>")
    page.save(:validate => false)

    website.menus.build(:order => 0, :name => "About", :page => page)

    # Contact
    page = ContactPage.new(:website => website, :user => user)
    page.name = "Contact"
    page.slug = "contact"
    page.title = "Contact Us"
    page.status = Page::PUBLIC
    page.body = loremipsum.split("\n\n")[0, 1].join("<br><br>")
    page.send_to = "null@zapfol.io"
    page.thanks_text = "Thanks! We will get back to you within one or two business days."
    page.fields.build(:name => "Where did you hear about us?", :input_type => "text_field", :placeholder => "Friends, Family, etc")
    page.fields.build(:name => "Wedding Date", :input_type => "text_field", :placeholder => "March 21st, 2013", :required => true)
    page.save(:validate => false)

    website.menus.build(:order => 1, :name => "Contact", :page => page)

    # Static Page
    page = StaticPage.new(:website => website, :user => user)
    page.name = "Home"
    page.slug = "home"
    page.title = "Welcome to my site"
    page.status = Page::PUBLIC
    page.body = loremipsum.split("\n\n")[0, 2].join("<br><br>")
    page.save(:validate => false)

    website.home_page = page

    # Media pages
    media_menu = website.menus.build(:order => 2, :name => "Media", :opened => true)

    # Media Carousel
    page = MediaCarouselPage.new(:website => website, :user => user)
    page.name = "Carousel Example"
    page.slug = "media/carousel"
    page.randomize = true
    page.album_ids = [album_map["502810444970cf702b000002"], album_map["502810444970cf702b000003"]]
    page.status = Page::PUBLIC
    page.per_page = 6
    page.save(:validate => false)

    media_menu.sub_menus.build(:order => 0, :name => "Carousel", :page => page)

    # Media Grid
    page = MediaGridPage.new(:website => website, :user => user)
    page.name = "Grid Example"
    page.slug = "media/grid"
    page.album_ids = [album_map["502810444970cf702b000002"], album_map["502810444970cf702b000003"]]
    page.status = Page::PUBLIC
    page.title = "Grid"
    page.body = "<b>For example,</b> you can add HTML and arbitrary text to a page, including media pages."
    page.save(:validate => false)

    media_menu.sub_menus.build(:order => 1, :name => "Grid", :page => page)

    # Media Row (Horizontal)
    page = MediaRowPage.new(:website => website, :user => user)
    page.name = "Horizontal Row Example"
    page.slug = "media/horiz"
    page.album_ids = [album_map["502810444970cf702b000002"], album_map["502810444970cf702b000003"]]
    page.status = Page::PUBLIC
    page.grow_in = MediaRowPage::HORIZONTAL
    page.save(:validate => false)

    media_menu.sub_menus.build(:order => 2, :name => "Horizontal", :page => page)

    # Media Row (Vertical)
    page = MediaRowPage.new(:website => website, :user => user)
    page.name = "Vertical Row Example"
    page.slug = "media/vert"
    page.album_ids = [album_map["502810444970cf702b000002"], album_map["502810444970cf702b000003"]]
    page.status = Page::PUBLIC
    page.grow_in = MediaRowPage::VERTICAL
    page.save(:validate => false)

    media_menu.sub_menus.build(:order => 3, :name => "Vertical", :page => page)

    website.save(:validate => false)

    # Log them in
    reset_session

    session[:user_id] = user._id.to_s
    cookies.permanent[:isdemo] = {:value => "1", :httponly => true}
    cookies.permanent.signed[:remember_token] = {:value => user.remember_token, :httponly => true}
    cookies.permanent.signed[:aid] = user.analytics_id

    if request.post?
      render :text => websites_path
    else
      redirect_to websites_path
    end
  end
end