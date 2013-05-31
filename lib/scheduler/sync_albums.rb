module Scheduler
  class SyncAlbums
    @queue = :scheduled

    def self.perform
      while true
        user = User.collection.find_and_modify(:query => {:next_sync => {"$lte" => Time.now.utc}}, :update => {"$set" => {:next_sync => Time.now.utc + 12.hours}}, :sort => [[:next_sync, Mongo::DESCENDING]])
        break unless user

        if user["provider"] == "flickr"
          klass = Job::Flickr::Album
        elsif user["provider"] == "smugmug"
          klass = Job::Smugmug::Album
        end

        plan = user["subscription"] ? user["subscription"]["plan"] : :free

        uuid = klass.create_to(CONFIG[:subscriptions][plan][:features][:queue] || :low, :user_id => user["_id"])
        User.set(user["_id"], "jobs.album" => uuid)
      end
    end
  end
end