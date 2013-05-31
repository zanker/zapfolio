require "job_helper"

describe Job::Flickr::Media do
  include MongoMocker::Finders
  include FlickrMocker

  it "loads all media for the user" do
    user = build(:flickr_user)
    album = create(:flickr_album, :user_id => user._id, :provider_id => "12344321")
    bad_media = create(:flickr_photo, :user_id => user._id)
    create(:flickr_photo, :user_id => user._id, :provider_id => "4897060082", :album_ids => [album._id])
    create(:flickr_photo, :user_id => user._id, :provider_id => "4887186195", :album_ids => [album._id])

    mock_finder(user)
    mock_flickr(:api => "photos.getCounts", :body => Responses::FLICKR[:photos][:getCounts], "user_id" => user.uid)
    mock_flickr(:api => "photos.search", :body => Responses::FLICKR[:photos][:search_1], "user_id" => user.uid, "per_page" => "500", "page" => "1", "extras" => "tags,date_upload,last_update,description,original_format,url_sq,url_t,url_s,url_q,url_m,url_n,url_z,url_c,url_l,url_o,media")
    mock_flickr(:api => "photos.search", :body => Responses::FLICKR[:photos][:search_2], "user_id" => user.uid, "per_page" => "500", "page" => "2", "extras" => "tags,date_upload,last_update,description,original_format,url_sq,url_t,url_s,url_q,url_m,url_n,url_z,url_c,url_l,url_o,media")

    Job::Flickr::Media.perform("1234", {"user_id" => user._id.to_s})

    Media.where(:user_id => user._id).count.should == 4

    Media.where(:_id => bad_media._id).exists?.should_not be_true

    media = user.medias.where(:provider => "flickr", :provider_id => "4897060082").first
    media.should_not be_nil
    media.title.should == "graph"
    media.height.should == 1497
    media.width.should == 2251
    media.privacy.should == Media::PUBLIC
    media.prov_created.should == Time.at(1281940162).utc
    media.prov_updated.should == Time.at(1281940163).utc
    media.tags.should == ["foo", "bar", "apple", "orange"]
    media.album_ids.should == [album._id]
    media.prov_info.should == {"secret" => "361d53b5bd", "server" => 4121, "farm" => 5, "origsecret" => "aa5e979556", "origformat" => "jpg"}

    media = user.medias.where(:provider => "flickr", :provider_id => "4897040252").first
    media.should_not be_nil
    media.title.should == "race"
    media.height.should == 413
    media.width.should == 996
    media.privacy.should == Media::PUBLIC
    media.prov_created.should == Time.at(1281939523).utc
    media.prov_updated.should == Time.at(1281939526).utc
    media.tags.should have(0).items
    media.description.should be_nil
    media.prov_info.should == {"secret" => "b1b71cb03b", "server" => 4081, "farm" => 5}

    media = user.medias.where(:provider => "flickr", :provider_id => "4887186195").first
    media.should_not be_nil
    media.title.should == "graph"
    media.height.should == 417
    media.width.should == 992
    media.tags.should have(0).items
    media.description.should be_nil
    media.prov_created.should == Time.at(1281690950).utc
    media.prov_updated.should == Time.at(1334539749).utc
    media.privacy.should == Media::PRIVATE
    media.prov_info.should == {"secret" => "5c0b6aea11", "server" => 4139, "farm" => 5}

    media = user.medias.where(:provider => "flickr", :provider_id => "4887739054").first
    media.should_not be_nil
    media.title.should == "graphs"
    media.description.should == "Foo Description"
    media.privacy.should == Media::PUBLIC
    media.tags.should have(0).items
    media.prov_created.should == Time.at(1281688659).utc
    media.prov_updated.should == Time.at(1334539888).utc
    media.height.should == 1024
    media.width.should == 932

    album.reload
    album.privacy.should == Album::MIXED
  end

  it "handles media limits" do
    user = build(:flickr_user)
    user.stub(:feature_limit).and_return(2)

    mock_finder(user)
    mock_flickr(:api => "photos.getCounts", :body => Responses::FLICKR[:photos][:getCounts], "user_id" => user.uid)
    mock_flickr(:api => "photos.search", :body => Responses::FLICKR[:photos][:search_1], "user_id" => user.uid, "per_page" => "500", "page" => "1", "extras" => "tags,date_upload,last_update,description,original_format,url_sq,url_t,url_s,url_q,url_m,url_n,url_z,url_c,url_l,url_o,media")
    mock_flickr(:api => "photos.search", :body => Responses::FLICKR[:photos][:search_2], "user_id" => user.uid, "per_page" => "500", "page" => "2", "extras" => "tags,date_upload,last_update,description,original_format,url_sq,url_t,url_s,url_q,url_m,url_n,url_z,url_c,url_l,url_o,media")

    Job::Flickr::Media.perform("1234", {"user_id" => user._id.to_s})

    Media.where(:user_id => user._id).count.should == 4

    media = user.medias.where(:provider => "flickr", :provider_id => "4897040252").first
    media.should_not be_nil
    media.title.should == "race"
    media.height.should == 413
    media.width.should == 996
    media.privacy.should == Media::PUBLIC
    media.pub_flag.should == Media::INACTIVE
    media.prov_created.should == Time.at(1281939523).utc
    media.prov_updated.should == Time.at(1281939526).utc
    media.prov_info.should == {"secret" => "b1b71cb03b", "server" => 4081, "farm" => 5}

    media = user.medias.where(:provider => "flickr", :provider_id => "4897060082").first
    media.should_not be_nil
    media.title.should == "graph"
    media.privacy.should == Media::PUBLIC
    media.pub_flag.should == Media::INACTIVE
    media.prov_created.should == Time.at(1281940162).utc
    media.prov_updated.should == Time.at(1281940163).utc
    media.prov_info.should == {"secret" => "361d53b5bd", "server" => 4121, "farm" => 5, "origsecret" => "aa5e979556", "origformat" => "jpg"}

    media = user.medias.where(:provider => "flickr", :provider_id => "4887186195").first
    media.should_not be_nil
    media.title.should == "graph"
    media.privacy.should == Media::PRIVATE
    media.pub_flag.should == Media::ACTIVE
    media.prov_created.should == Time.at(1281690950).utc
    media.prov_updated.should == Time.at(1334539749).utc
    media.prov_info.should == {"secret" => "5c0b6aea11", "server" => 4139, "farm" => 5}

    media = user.medias.where(:provider => "flickr", :provider_id => "4887739054").first
    media.should_not be_nil
    media.title.should == "graphs"
    media.description.should == "Foo Description"
    media.privacy.should == Media::PUBLIC
    media.pub_flag.should == Media::ACTIVE
    media.prov_created.should == Time.at(1281688659).utc
    media.prov_updated.should == Time.at(1334539888).utc
  end
end