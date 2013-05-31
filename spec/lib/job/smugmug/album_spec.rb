require "job_helper"

describe Job::Smugmug::Album do
  include MongoMocker::Finders
  include SmugMugMocker

  it "pulls a list of albums" do
    user = build(:smugmug_user)
    inactive_album = create(:smugmug_album, :user_id => user._id)
    bad_media = create(:smugmug_photo, :album_ids => [inactive_album._id], :user_id => user._id)

    website = create(:website, :user => user)
    gen_cache_key = website.cache_bust["gen"]
    page = create(:media_grid_page, :website => website, :user => user, :album_ids => [inactive_album._id])

    misc_page = create(:media_grid_page, :website => website, :user => user, :album_ids => [BSON::ObjectId.new])

    mock_finder(user)
    mock_smugmug("albums.get", {:Heavy => true}, Responses::SMUGMUG[:albums][:get_heavy])
    Job::Smugmug::Media.should_receive(:create).with(hash_including(:user_id => user._id))

    Job::Smugmug::Album.perform("1234", {"user_id" => user._id.to_s})

    Album.where(:user_id => user._id).count.should == 2

    # This is purely meant as a safety check
    Album::PRIVATE.should_not == Album::PUBLIC

    album = user.albums.where(:provider_id => "24080102").first
    album.should_not be_nil
    album.provider.should == "smugmug"
    album.title.should == "Test"
    album.description.should == "This is a description, it's also new."
    album.cnt_photos.should == 2
    album.cnt_videos.should == 0
    album.prov_created.should == Time.at(1342496482).utc
    album.prov_updated.should == Time.at(1342496482).utc
    album.prov_info.should == {"key" => "Ka2Wx9", "l" => true, "xl" => false, "x2l" => false, "x3l" => false, "sqthumb" => true, "o" => false}
    album.privacy.should == Album::PRIVATE

    album = user.albums.where(:provider_id => "24080103").first
    album.should_not be_nil
    album.provider.should == "smugmug"
    album.title.should == "Test 2"
    album.description.should == "This is a description."
    album.cnt_photos.should == 1
    album.cnt_videos.should == 0
    album.prov_created.should == Time.at(1342500622).utc
    album.prov_updated.should == Time.at(1342500622).utc
    album.prov_info.should == {"key" => "Ka2Wx4", "l" => false, "xl" => false, "x2l" => false, "x3l" => false, "sqthumb" => true, "o" => false}
    album.privacy.should == Album::PUBLIC

    # Make sure we deleted the inactive album
    Album.where(:_id => inactive_album._id).exists?.should_not be_true

    # Media that's no longer part of this album
    Media.where(:_id => bad_media._id).exists?.should_not be_true

    # Do our cache checks
    website.reload
    website.cache_bust["gen"].should_not == gen_cache_key

    page.reload
    page.album_ids.should have(0).albums
    page.data_updated_at.to_i.should be_within(5).of(Time.now.utc.to_i)

    misc_page.reload
    misc_page.album_ids.should have(1).album
    misc_page.data_updated_at.should be_nil
  end
end