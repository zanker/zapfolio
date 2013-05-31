require "flickraw-cached"

module Job; module Flickr end end

class Job::Flickr::Media
  include Resque::Plugins::Status
  @queue = :high

  def perform
    at(0, 1, :area => :starting)

    user = User.find(options["user_id"])

    FlickRaw.api_key, FlickRaw.shared_secret, FlickRaw.secure = CONFIG[:oauth][:flickr][:key], CONFIG[:oauth][:flickr][:secret], Rails.env.worker?
    flickr = FlickRaw::Flickr.new
    flickr.instance_variable_set(:@access_token, user.oauth["token"])
    flickr.instance_variable_set(:@access_secret, user.oauth["secret"])

    photo_sizes, album_privacy = ["o", "l", "c", "z", "m", "n", "s", "t", "q", "sq"], {}
    started, page, loaded_photos = Time.now.utc, 1, 0

    total_photos = flickr.photos.getCounts(:user_id => user.uid, :dates => "0,#{Time.now.utc.to_i + 1.day}")
    if total_photos
      total_photos = total_photos.first["count"].to_i
    else
      total_photos = 999999
    end

    total_steps = total_photos + 3

    at(0, total_steps, :area => :photos, :total => total_photos, :loaded => 0)

    while page <= 10000 do
      photos = flickr.photos.search(:user_id => user.uid, :per_page => 500, :page => page, :extras => "tags,date_upload,last_update,description,original_format,url_sq,url_t,url_s,url_q,url_m,url_n,url_z,url_c,url_l,url_o,media")
      next unless photos.photo

      photos.photo.each do |data|
        media = Media.where(:user_id => user._id, :provider => "flickr", :provider_id => data["id"]).first
        unless media
          media = Media.new(:user_id => user._id, :provider => "flickr", :provider_id => data["id"], :pub_flag => Media::ACTIVE)
        end

        # Go from biggest to smallest
        photo_sizes.each do |key|
          if data["url_#{key}"]
            media.height, media.width = data["height_#{key}"].to_i, data["width_#{key}"].to_i
            break
          end
        end

        media.title = data["title"].blank? ? nil : data["title"]
        media.description = data["description"].blank? ? nil : data["description"]
        media.prov_created = Time.at(data["dateupload"].to_i).utc
        media.prov_updated = Time.at(data["lastupdate"].to_i).utc
        media.privacy = data["ispublic"] == 1 ? Media::PUBLIC : Media::PRIVATE
        media.type = data["media"] == "video" ? Media::VIDEO : Media::PHOTO
        media.tags = data["tags"].split(" ")
        media.prov_info = {"secret" => data["secret"], "server" => data["server"].to_i, "farm" => data["farm"].to_i}
        media.prov_info["origsecret"] = data["originalsecret"] if data["originalsecret"]
        media.prov_info["origformat"] = data["originalformat"] if data["originalformat"]
        media.pub_flag = Media::ACTIVE
        media.save(:validate => false)

        # Figure out what the privacy status of the album is
        if media.album_ids
          media.album_ids.each do |album_id|
            next if album_privacy[album_id] == Album::MIXED
            flag = media.privacy == Media::PUBLIC ? Album::PUBLIC : Album::PRIVATE

            if album_privacy[album_id] and album_privacy[album_id] != flag
              album_privacy[album_id] = Album::MIXED
            else
              album_privacy[album_id] = flag
            end
          end
        end

        loaded_photos += 1
        at(loaded_photos, total_photos, :area => :photos)
      end

      break if photos["page"] >= photos["pages"]
      page += 1
    end

    # Now update the album status and push it out
    at(total_steps - 2, total_steps, :area => :cleaning)
    grouped = {}
    album_privacy.each do |album_id, status|
      grouped[status] ||= []
      grouped[status].push(album_id)
    end

    grouped.each do |status, list|
      Album.set({:user_id => user._id, :_id.in => list}, :privacy => status)
    end

    # Remove any photos we couldn't find
    at(total_steps - 1, total_steps, :area => :cleaning)
    Media.destroy_all(:user_id => user._id, :provider => "flickr", :updated_at.lt => started)

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