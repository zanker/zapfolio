require "flickraw-cached"

module Job; module Flickr end end

class Job::Flickr::Album
  include Resque::Plugins::Status
  @queue = :high

  def perform
    at(0, 2, :area => :starting)

    user = User.find(options["user_id"])

    FlickRaw.api_key, FlickRaw.shared_secret, FlickRaw.secure = CONFIG[:oauth][:flickr][:key], CONFIG[:oauth][:flickr][:secret], Rails.env.worker?
    flickr = FlickRaw::Flickr.new
    flickr.instance_variable_set(:@access_token, user.oauth["token"])
    flickr.instance_variable_set(:@access_secret, user.oauth["secret"])

    started = Time.now.utc

    albums = flickr.photosets.getList(:user_id => user.uid).photoset.map do |set|
      at(1, 2, :area => :albums, :album => set["title"])

      album = Album.where(:user_id => user._id, :provider => "flickr", :provider_id => set["id"]).first
      unless album
        album = Album.new(:user_id => user._id, :provider => "flickr", :provider_id => set["id"])
      end

      album.title = set["title"].blank? ? nil : set["title"]
      album.description = set["description"].blank? ? nil : set["description"]
      album.cnt_photos = set["photos"].to_i
      album.cnt_videos = set["videos"].to_i
      album.prov_created = Time.at(set["date_create"].to_i).utc
      album.prov_updated = Time.at(set["date_update"].to_i).utc
      album.prov_info = {"primary" => set["primary"].to_i, "secret" => set["secret"], "server" => set["server"].to_i, "farm" => set["farm"].to_i}
      album.syncing = true if album.new_record? or album.prov_updated_changed?
      album.save(:validate => false)

      album
    end

    deleted_albums = nil
    Album.where(:user_id => user._id, :provider => "flickr", :updated_at.lt => started).each do |album|
      Media.pull({:user_id => user._id, :provider => "flickr", :album_ids.in => [album._id]}, :album_ids => album._id)
      Page.collection.update({:user_id => user._id, :album_ids => {"$in" => [album._id]}}, {"$pull" => {:album_ids => album._id}, "$set" => {:data_updated_at => Time.now.utc}}, {:multi => true})

      deleted_albums = true

      album.destroy
    end

    # Load all of the media associations
    changed_albums = {}

    albums.each do |album|
      started, page = Time.now.utc, 1
      while page <= 10000
        photoset = flickr.photosets.getPhotos(:photoset_id => album.provider_id, :extras => "date_upload,last_update,media")
        break if photoset.photo.empty?

        at(photoset["page"], photoset["pages"] + 1, :area => :album_meta, :album => album.title)

        photoset.photo.each do |data|
          media = Media.where(:user_id => album.user_id, :provider => "flickr", :provider_id => data["id"]).first
          unless media
            media = Media.new(:user_id => album.user_id, :provider => "flickr", :provider_id => data["id"], :pub_flag => Media::INACTIVE)
          end

          media.type = data["media"] == "video" ? Media::VIDEO : Media::PHOTO
          media.prov_updated = Time.at(data["lastupdate"].to_i).utc
          media.prov_info = {"secret" => data["secret"], "server" => data["server"].to_i, "farm" => data["farm"].to_i}
          media.album_ids.push(album._id)
          media.album_ids.uniq!

          if media.new_record? or media.prov_updated_changed?
            changed_albums[album._id] = true
          end

          media.save(:validate => false)
        end

        # Next page!
        break if photoset["pages"].to_i >= photoset["page"].to_i
        page = photoset["page"] + 1
      end

      if Media.where(:user_id => album.user_id, :provider => "Flickr", :updated_at.lt => started, :album_ids.in => [album._id]).exists?
        changed_albums[album._id] = true
      end

      Media.pull({:user_id => album.user_id, :provider => "flickr", :updated_at.lt => started, :album_ids.in => [album._id]}, :album_ids => album._id)
    end

    # Update flags
    unless changed_albums.empty?
      Page.set({:user_id => user._id, :album_ids.in => changed_albums.keys}, {:data_updated_at => Time.now.utc})
    end

    unless changed_albums.empty? and !deleted_albums
      Website.set({:user_id => user._id}, "cache_bust.gen" => SecureRandom.hex(4))
    end

    # Remove any media that is no longer associated to an album
    Media.destroy_all(:album_ids => {"$size" => 0})

    uuid = Job::Flickr::Media.create(:user_id => user._id)
    user.set("jobs.media" => uuid)

    user.reset_sync_timer!
  end
end