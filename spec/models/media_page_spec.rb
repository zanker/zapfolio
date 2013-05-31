require "spec_helper"

describe MediaPage do
  before :all do
    @user = create(:flickr_user)
    @album = create(:flickr_album, :user => @user)
    @public_media = create(:flickr_photo, :privacy => Media::PUBLIC, :pub_flag => Media::ACTIVE, :album_ids => [@album._id], :user => @user)
    @private_media = create(:flickr_photo, :privacy => Media::PRIVATE, :pub_flag => Media::ACTIVE, :album_ids => [@album._id], :user => @user)

    # Random misc data to make sure nothing is leaking
    misc_album = create(:flickr_album, :user => @user)
    create(:flickr_photo, :privacy => Media::PUBLIC, :pub_flag => Media::INACTIVE, :album_ids => [@album._id, misc_album._id], :user => @user)
    create(:flickr_photo, :privacy => Media::PUBLIC, :pub_flag => Media::ACTIVE, :album_ids => [misc_album._id], :user => @user)
    create(:flickr_photo, :privacy => Media::PRIVATE, :pub_flag => Media::ACTIVE, :album_ids => [], :user => @user)

    # Test to make sure no other users media will leak
    misc_user = create(:flickr_user)
    # Even if you specify the album_id of another user
    create(:flickr_photo, :privacy => Media::PUBLIC, :pub_flag => Media::INACTIVE, :album_ids => [misc_album._id], :user => misc_user)
    create(:flickr_photo, :privacy => Media::PUBLIC, :pub_flag => Media::INACTIVE, :album_ids => [], :user => misc_user)
  end

  it "pulls out only public media" do
    page = build(:media_page, :album_ids => [@album._id], :user => @user)

    media_ids = page.media.only(:_id).map {|m| m._id}
    media_ids.should == [@public_media._id]
  end

  it "pulls out public and private media" do
    page = build(:media_page, :album_ids => [@album._id], :encrypted_password => "12341234", :user => @user)

    media_ids = page.media.only(:_id).map {|m| m._id}
    media_ids.should == [@public_media._id, @private_media._id]
  end

  it "limits how much media is pulled out" do
    page = build(:media_page, :album_ids => [@album._id], :encrypted_password => "12341234", :max_media => 1, :user => @user)

    media_ids = page.media.only(:_id).map {|m| m._id}
    media_ids.should == [@public_media._id]
  end
end