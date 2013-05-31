require "job_helper"

describe Scheduler::PruneDemo do
  it "queues album syncs" do
    expired_user = create(:flickr_user, :demo_expires => 1.hour.ago.utc)
    expired_website = create(:website, :user => expired_user, :demo => true)
    expired_page = create(:page, :website => expired_website, :user => expired_user)
    expired_album = create(:flickr_album, :user => expired_user)
    expired_media = create(:flickr_photo, :user => expired_user, :album_ids => [expired_album._id])

    active_user = create(:flickr_user, :demo_expires => 1.hour.from_now.utc)
    active_website = create(:website, :user => active_user)

    Scheduler::PruneDemo.perform

    User.where(:_id => expired_user._id).exists?.should_not be_true
    Website.where(:_id => expired_website._id).exists?.should_not be_true
    Page.where(:_id => expired_page._id).exists?.should_not be_true
    Album.where(:_id => expired_album._id).exists?.should_not be_true
    Media.where(:_id => expired_media._id).exists?.should_not be_true

    User.where(:_id => active_user._id).exists?.should be_true
    Website.where(:_id => active_website._id).exists?.should be_true
  end
end