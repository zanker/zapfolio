module Scheduler
  class PruneDemo
    @queue = :scheduled

    def self.perform
      User.where(:demo_expires.lte => Time.now.utc).each do |user|
        next unless user.demo_expires?
        next unless Website.where(:user_id => user._id, :demo => true).exists?

        # Strip these so when the accounts cleaned up the test media is kept
        Website.unset({:user_id => user._id}, :logo_uid)
        Page.unset({:user_id => user._id, :picture_uid => {"$exists" => true}}, :picture_uid)

        user.destroy
      end
    end
  end
end