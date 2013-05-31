require "ruby-smugmug"

module Job; module SmugMug end end

class Job::Smugmug::Album
  include Resque::Plugins::Status
  @queue = :high

  def perform
    at(0, 2, :area => :starting)

    user = User.find(options["user_id"])

    smugmug = SmugMug::Client.new(:user => {:token => user.oauth["token"], :secret => user.oauth["secret"]}, :api_key => CONFIG[:oauth][:smugmug][:key], :oauth_secret => CONFIG[:oauth][:smugmug][:secret])

    started = Time.now.utc

    smugmug.albums.get(:Heavy => true).each do |set|
      at(1, 2, :area => :albums, :album => set["Title"])

      album = Album.where(:user_id => user._id, :provider => "smugmug", :provider_id => set["id"].to_s).first
      unless album
        album = Album.new(:user_id => user._id, :provider => "smugmug", :provider_id => set["id"].to_s)
      end

      album.title = set["Title"].blank? ? nil : set["Title"]
      album.description = set["Description"].blank? ? nil : set["Description"]
      album.cnt_photos = set["ImageCount"].to_i
      album.cnt_videos = 0
      album.prov_updated = Time.parse(set["LastUpdated"]).utc
      album.prov_created ||= album.prov_updated
      album.prov_info = {"key" => set["Key"], "l" => set["Larges"], "xl" => set["XLarges"], "x2l" => set["X2Larges"], "x3l" => set["X3Larges"], "sqthumb" => set["SquareThumbs"], "o" => set["Originals"]}
      album.syncing = true if album.new_record? or album.prov_updated_changed?

      album.privacy = Album::PRIVATE
      if set["Public"] and !set["Passworded"]
        album.privacy = Album::PUBLIC
      end

      album.save(:validate => false)
    end

    album_deleted = nil
    Album.where(:user_id => user._id, :provider => "smugmug", :updated_at.lt => started).each do |album|
      Media.destroy_all(:user_id => album.user_id, :provider => "smugmug", :album_ids => {"$in" => [album._id]})
      Page.collection.update({:user_id => user._id, :album_ids => {"$in" => [album._id]}}, {"$pull" => {:album_ids => album._id}, "$set" => {:data_updated_at => Time.now.utc}}, {:multi => true})

      album.destroy
      album_deleted = true
    end

    if album_deleted
      Website.set({:user_id => user._id}, "cache_bust.gen" => SecureRandom.hex(4))
    end

    uuid = Job::Smugmug::Media.create(:user_id => user._id)
    user.set("jobs.media" => uuid)

    user.reset_sync_timer!
  end
end