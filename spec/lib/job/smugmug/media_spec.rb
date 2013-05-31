require "job_helper"

describe Job::Smugmug::Album do
  include MongoMocker::Finders
  include SmugMugMocker

  it "loads all media for the user" do
    user = build(:smugmug_user)
    album = create(:smugmug_album, :user_id => user._id, :provider_id => "24080102", :prov_info => {"key" => "Ka2Wx9"})

    bad_media = create(:smugmug_photo, :user_id => user._id)
    existing_media = create(:smugmug_photo, :user_id => user._id, :provider_id => "1955880317", :album_ids => [album._id], :description => "Old Caption")

    website = create(:website, :user => user)
    gen_cache_key = website.cache_bust["gen"]
    page = create(:media_grid_page, :website => website, :user => user, :album_ids => [album._id])
    misc_page = create(:media_grid_page, :website => website, :user => user, :album_ids => [BSON::ObjectId.new])

    mock_finder(user)
    mock_smugmug("images.get", {:AlbumID => album.provider_id, :AlbumKey => album.prov_info["key"]}, Responses::SMUGMUG[:images][:get_extras_1])

    Job::Smugmug::Media.perform("1234", {"user_id" => user._id.to_s})

    Media.where(:user_id => user._id).count.should == 2

    # Safety check
    Media::PRIVATE.should_not == Media::PUBLIC

    Media.where(:_id => bad_media._id).exists?.should_not be_true

    media = existing_media.reload
    media.should_not be_nil
    media.title.should be_nil
    media.width.should == 337
    media.height.should == 450
    media.privacy.should == Media::PRIVATE
    media.pub_flag.should == Media::ACTIVE
    media.prov_created.should == Time.parse("2012-07-09 19:50:06").utc
    media.prov_updated.should == Time.parse("2012-07-09 19:50:20").utc
    media.tags.should have(0).items
    media.album_ids.should == [album._id]
    media.prov_info.should == {"key" => "HskGh8W", "format" => "JPG", "username" => "zapfolio", "owidth" => 768, "oheight" => 1025}

    media = user.medias.where(:provider => "smugmug", :provider_id => "1955880811").first
    media.should_not be_nil
    media.title.should be_nil
    media.description.should == "Another test caption"
    media.width.should == 600
    media.height.should == 436
    media.privacy.should == Media::PRIVATE
    media.pub_flag.should == Media::ACTIVE
    media.prov_created.should == Time.parse("2012-07-09 18:50:07").utc
    media.prov_updated.should == Time.parse("2012-07-12 19:50:25").utc
    media.tags.should have(0).items
    media.album_ids.should == [album._id]
    media.prov_info.should == {"key" => "K6X9hwr", "format" => "PNG", "username" => "zapfolio", "owidth" => 1100, "oheight" => 800}

    # Do our cache checks
    website.reload
    website.cache_bust["gen"].should_not == gen_cache_key

    page.reload
    page.data_updated_at.to_i.should be_within(5).of(Time.now.utc.to_i)

    misc_page.reload
    misc_page.data_updated_at.should be_nil
  end

  it "handles media limits" do
    user = build(:smugmug_user)

    album = create(:smugmug_album, :user_id => user._id, :provider_id => "24080102", :prov_info => {"key" => "Ka2Wx9"})

    mock_finder(user)
    user.stub(:feature_limit).and_return(1)

    mock_smugmug("images.get", {:AlbumID => album.provider_id, :AlbumKey => album.prov_info["key"]}, Responses::SMUGMUG[:images][:get_extras_1])

    Job::Smugmug::Media.perform("1234", {"user_id" => user._id.to_s})

    Media.where(:user_id => user._id).count.should == 2

    media = user.medias.where(:provider => "smugmug", :provider_id => "1955880317").first
    media.should_not be_nil
    media.width.should == 337
    media.height.should == 450
    media.privacy.should == Media::PRIVATE
    media.pub_flag.should == Media::INACTIVE
    media.prov_created.should == Time.parse("2012-07-09 19:50:06").utc
    media.prov_updated.should == Time.parse("2012-07-09 19:50:20").utc
    media.album_ids.should == [album._id]
    media.prov_info.should == {"key" => "HskGh8W", "format" => "JPG", "username" => "zapfolio", "owidth" => 768, "oheight" => 1025}

    media = user.medias.where(:provider => "smugmug", :provider_id => "1955880811").first
    media.should_not be_nil
    media.description.should == "Another test caption"
    media.width.should == 600
    media.height.should == 436
    media.privacy.should == Media::PRIVATE
    media.pub_flag.should == Media::ACTIVE
    media.prov_created.should == Time.parse("2012-07-09 18:50:07").utc
    media.prov_updated.should == Time.parse("2012-07-12 19:50:25").utc
    media.album_ids.should == [album._id]
    media.prov_info.should == {"key" => "K6X9hwr", "format" => "PNG", "username" => "zapfolio", "owidth" => 1100, "oheight" => 800}
  end
end