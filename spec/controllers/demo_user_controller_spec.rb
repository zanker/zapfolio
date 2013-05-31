require "spec_helper"

describe DemoUserController do
  before :each do
    User.delete_all(:demo_expires.exists => true)
  end

  it "does not allow multiple demo accounts to be created by the same ip" do
    create(:flickr_user, :demo_expires => 1.hour.from_now.utc, :current_sign_in_ip => "0.0.0.0")

    get(:create)
    response.should redirect_to(new_session_path)

    User.where(:demo_expires.exists => true).count.should == 1
  end

  it "creates a demo account" do
    request.cookie_jar.signed[:aid] = "13244321"

    get(:create)
    response.should redirect_to(websites_path)

    cookies[:isdemo].should == "1"

    remember_token = Marshal.load(Base64.decode64(cookies[:remember_token].split("--").first))

    user = User.where(:_id => session[:user_id], :remember_token => remember_token).first
    user.should_not be_nil
    user.demo_expires.to_i.should be_within(5).of(Time.now.utc.to_i + CONFIG[:demo_length])
    user.current_sign_in_at.to_i.should be_within(5).of(Time.now.utc.to_i)
    user.current_sign_in_ip.should == request.ip
    user.analytics_id.should == "13244321"

    rand_id = user.email.match(/null\+([0-9]+)@/)
    rand_id = rand_id[1]
    rand_id.should_not be_nil

    Album.where(:user_id => user._id).count.should == 3
    Media.where(:user_id => user._id).count.should == 30
    Media.where(:user_id => user._id, :privacy => Media::PUBLIC).count.should == 22
    Media.where(:user_id => user._id, :privacy => Media::PRIVATE).count.should == 8

    website = Website.where(:user_id => user._id).first
    website.should_not be_nil
    website.demo.should be_true
    website.logo_uid.should == "demo/logo.png"
    website.subdomain.should == "demo-#{rand_id}"
    website.menus.should have_at_least(3).items

    AboutPage.where(:user_id => user._id, :website_id => website._id).count.should == 1
    ContactPage.where(:user_id => user._id, :website_id => website._id).count.should == 1
    Page.where(:user_id => user._id, :website_id => website._id, :_type => [StaticPage.name.to_s]).count.should == 1
    MediaCarouselPage.where(:user_id => user._id, :website_id => website._id).count.should == 1
    MediaGridPage.where(:user_id => user._id, :website_id => website._id).count.should == 1
    MediaRowPage.where(:user_id => user._id, :website_id => website._id, :grow_in => MediaRowPage::HORIZONTAL).count.should == 1
    MediaRowPage.where(:user_id => user._id, :website_id => website._id, :grow_in => MediaRowPage::VERTICAL).count.should == 1
  end
end