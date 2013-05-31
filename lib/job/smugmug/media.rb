require "ruby-smugmug"

module Job; module SmugMug end end

class Job::Smugmug::Media
  include Resque::Plugins::Status
  @queue = :high

  # http://help.smugmug.com/customer/portal/articles/93250
  SIZES = [["o"], ["x3l", 1600, 1200], ["x2l", 1280, 960], ["xl", 1024, 768], ["l", 800, 600], ["m", 600, 450]]

  def perform
    at(0, 1, :area => :starting)

    user = User.find(options["user_id"])
    smugmug = SmugMug::Client.new(:user => {:token => user.oauth["token"], :secret => user.oauth["secret"]}, :api_key => CONFIG[:oauth][:smugmug][:key], :oauth_secret => CONFIG[:oauth][:smugmug][:secret])

    total_photos = 0
    user.albums.where(:provider => "smugmug").only(:cnt_photos).each {|a| total_photos += a.cnt_photos}

    started, loaded_photos, total_steps = Time.now.utc, 0, (total_photos + 2)

    at(0, total_steps, :area => :photos, :total => total_photos, :loaded => 0)

    changed_albums = {}

    user.albums.where(:provider => "smugmug").each do |album|
      album_photos = smugmug.images.get(:AlbumID => album.provider_id, :AlbumKey => album.prov_info["key"], :Extras => "Height,Width,Format,LastUpdated,Caption,Date,Hidden,Duration")

      # Figure out if we have any size restrictions
      max_width, max_height = SIZES.last[1], SIZES.last[2]
      SIZES.each do |key, width, height|
        if album.prov_info[key]
          max_width, max_height = width, height
          break
        end
      end

      # Figure out the users SmugMug username. We do this here in case it changed since they first signed up
      username = album_photos["URL"].match(/http:\/\/(.+)\.smugmug\.com/)
      # URL should never change, but will default to what they signed up with in case it does
      username = username ? username[1] : user.username

      # Load media
      album_photos["Images"].each do |data|
        media = Media.where(:user_id => user._id, :provider => "smugmug", :provider_id => data["id"].to_s).first
        unless media
          media = Media.new(:user_id => user._id, :provider => "smugmug", :provider_id => data["id"].to_s, :pub_flag => Media::ACTIVE)
        end

        # Determine the maximum allowed size as SmugMug doesn't do this automatically
        media.width = data["Width"].to_i
        media.height = data["Height"].to_i

        if max_width and max_height and ( media.width > max_width or media.height > max.height )
          ratio = media.width > media.height ? (media.height.to_f / media.width) : (media.width.to_f / media.height)

          if media.width > media.height
            media.width, media.height = max_width, (max_width * ratio).round
          else
            media.width, media.height = (max_height * ratio).round, max_height
          end
        end

        media.description = data["Caption"].blank? ? nil : data["Caption"]
        media.prov_created = Time.parse(data["Date"]).utc
        media.prov_updated = Time.parse(data["LastUpdated"]).utc
        media.pub_flag = Media::ACTIVE
        media.type = data["Duration"].nil? ? Media::PHOTO : Media::VIDEO
        media.prov_info = {"key" => data["Key"], "format" => data["Format"], "username" => username, "owidth" => data["Width"].to_i, "oheight" => data["Height"].to_i}

        media.privacy = Media::PRIVATE
        if data["Hidden"] == false and album.privacy == Album::PUBLIC
          media.privacy = Media::PUBLIC
        end

        media.album_ids.push(album._id)
        media.album_ids.uniq!

        if media.new_record? or media.prov_updated_changed?
          media.album_ids.each {|id| changed_albums[id] = true}
        end

        media.save(:validate => false)

        loaded_photos += 1
        at(loaded_photos, total_photos, :area => :photos)
      end
    end

    # Remove any photos we couldn't find
    at(total_steps - 1, total_steps, :area => :cleaning)
    Media.destroy_all(:user_id => user._id, :provider => "smugmug", :updated_at.lt => started)

    # Cache bust
    unless changed_albums.empty?
      Page.set({:user_id => user._id, :album_ids.in => changed_albums.keys}, {:data_updated_at => Time.now.utc})
      Website.set({:user_id => user._id}, "cache_bust.gen" => SecureRandom.hex(4))
    end

    # Figure out how much media can be shown based on the sub
    media_limit = user.feature_limit(:media)
    if media_limit > 0
      dont_lock = Media.where(:user_id => user._id).only(:_id).sort([:prov_updated, :desc]).limit(media_limit).map {|m| m._id}
      Media.set({:user_id => user._id, :_id.nin => dont_lock}, {:pub_flag => Media::INACTIVE})
    end

    Album.unset({:user_id => user._id, :syncing => true}, :syncing)

    user.reset_sync_timer!
  end
end