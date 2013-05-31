require "job_helper"

describe Job::Flickr::Album do
  include MongoMocker::Finders
  include FlickrMocker

  it "pulls a list of albums" do
    user = build(:flickr_user)
    inactive_album = create(:flickr_album, :user_id => user._id)
    bad_media = create(:flickr_photo, :album_ids => [inactive_album._id], :user_id => user._id)

    website = create(:website, :user => user)
    gen_cache_key = website.cache_bust["gen"]
    page = create(:media_grid_page, :website => website, :user => user, :album_ids => [inactive_album._id])

    misc_page = create(:media_grid_page, :website => website, :user => user, :album_ids => [BSON::ObjectId.new])

    mock_finder(user)
    mock_flickr(:api => "photosets.getList", :body => Responses::FLICKR[:photosets][:getList], "user_id" => user.uid)
    mock_flickr(:api => "photosets.getPhotos", :body => Responses::FLICKR[:photosets][:getPhotos_1], "photoset_id" => "72157629451824118", "extras" => "date_upload,last_update,media")
    Job::Flickr::Media.should_receive(:create).with(hash_including(:user_id => user._id))

    Job::Flickr::Album.perform("1234", {"user_id" => user._id.to_s})

    Album.where(:user_id => user._id).count.should == 1

    album = user.albums.where(:provider_id => "72157629451824118").first
    album.should_not be_nil
    album.provider.should == "flickr"
    album.title.should == "Foo Bar"
    album.description.should == "This is a description"
    album.cnt_photos.should == 2
    album.cnt_videos.should == 0
    album.prov_created.should == Time.at(1334431047).utc
    album.prov_updated.should == Time.at(1334431049).utc
    album.prov_info.should == {"primary" => 4887186195, "secret" => "0157aa3a79", "server" => 4139, "farm" => 5}

    # Make sure we deleted the inactive album
    Album.where(:_id => inactive_album._id).exists?.should_not be_true

    # Media that's no longer part of this album
    Media.where(:_id => bad_media._id).exists?.should_not be_true

    # Check if we pulled the inline media too
    media = user.medias.where(:provider => "flickr", :provider_id => "4887186195").first
    media.should_not be_nil
    media.user_id.should == user._id
    media.album_ids.should == [album._id]
    media.type.should == Media::PHOTO
    media.pub_flag.should == Media::INACTIVE
    media.prov_info.should == {"secret" => "5c0b6aea11", "server" => 4139, "farm" => 5}

    media = user.medias.where(:provider => "flickr", :provider_id => "4887739054").first
    media.should_not be_nil
    media.user_id.should == user._id
    media.album_ids.should == [album._id]
    media.type.should == Media::VIDEO
    media.pub_flag.should == Media::INACTIVE
    media.prov_info.should == {"secret" => "9a44896946", "server" => 4117, "farm" => 5}

    # Check our cache busting for sitemaps
    website.reload
    website.cache_bust["gen"].should_not == gen_cache_key

    page.reload
    page.album_ids.should have(0).albums
    page.data_updated_at.to_i.should be_within(5).of(Time.now.utc.to_i)

    misc_page.reload
    misc_page.album_ids.should have(1).album
    misc_page.data_updated_at.should be_nil
  end

  it "removes media from an album if it wasn't found" do
    user = build(:flickr_user)
    album = create(:flickr_album, :user_id => user._id, :provider_id => "72157629451824118")
    inactive_media = create(:flickr_photo, :album_ids => [album._id], :user_id => user._id)

    mock_finder(user)
    mock_flickr(:api => "photosets.getList", :body => Responses::FLICKR[:photosets][:getList], "user_id" => user.uid)
    mock_flickr(:api => "photosets.getPhotos", :body => Responses::FLICKR[:photosets][:getPhotos_1], "photoset_id" => "72157629451824118", "extras" => "date_upload,last_update,media")
    Job::Flickr::Media.should_receive(:create).with(hash_including(:user_id => user._id))

    Job::Flickr::Album.perform("1234", {"user_id" => user._id.to_s})

    user.medias.where(:album_ids.in => [album._id]).count.should == 2

    Media.where(:_id => inactive_media._id).exists?.should_not be_true
  end
end