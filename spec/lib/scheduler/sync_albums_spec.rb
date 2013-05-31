require "job_helper"

describe Scheduler::SyncAlbums do
  it "queues album syncs" do
    sync_user = create(:flickr_user, :next_sync => 1.hour.ago.utc)
    create(:flickr_user, :next_sync => 5.days.from_now.utc)

    Job::Flickr::Album.should_receive(:create_to).once.with(:low, :user_id => sync_user._id).and_return("1234")
    User.should_receive(:set).once.with(sync_user._id, "jobs.album" => "1234")

    Scheduler::SyncAlbums.perform
  end

  it "queues album syncs based on subscription" do
    sync_user = create(:flickr_user, :next_sync => 1.hour.ago.utc, :subscription => build(:subscription, :plan => "premium"))

    Job::Flickr::Album.should_receive(:create_to).once.with(CONFIG[:subscriptions][:premium][:features][:queue], :user_id => sync_user._id).and_return("1234")
    User.should_receive(:set).once.with(sync_user._id, "jobs.album" => "1234")

    Scheduler::SyncAlbums.perform
  end
end