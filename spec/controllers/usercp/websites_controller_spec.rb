require "spec_helper"

describe Usercp::WebsitesController do
  before :all do
    @user = create(:flickr_user, :subscription => build(:subscription))
    @website = create(:website, :user => @user, :menus => [build(:menu, :sub_menus => [build(:sub_menu)])])
    @page = create(:page, :website => @website)
  end

  before :each do
    request.session[:user_id] = @user._id
    request.cookie_jar.signed[:remember_token] = @user.remember_token
  end

  it "updates a website" do
    put(:update, :home_page_id => @page._id, :favicon => fixture_file_upload(Rails.root.join("spec", "media", "favicon.ico"), "image/x-icon"), :logo => fixture_file_upload(Rails.root.join("spec", "media", "image.png"), "image/png"), :name => "Name", :subdomain => "apple", :domain => "www.foobar.com", :width => 50, :width_unit => "px", :menu_align => Website::RIGHT, :site_align => Website::CENTER, :custom_css => "body {color: red;}", :css_layout => "dark", :active_style => Website::CUSTOM, :css_base_layout => "light",:css_tags => {:background => "#FF", :text_color => "#AAA", :title_color => "#AAAAAA", :text_font => "Arial", :menu_text_font => "Foo Bar", :title_font => "Helvetica Neue", :menu_text_color => "rgba(200,99,13,0.51)", :menu_bg_active => "rgba(0,1,0.5)", :menu_bg_hover => "rgba(255,255,255,1)"}, :analytics => {:ga => "UA-1234-56"}, :social => {:twitter => "twitter"}, :menus => [{:id => @website.menus.first._id, :name => "Bar", :sub_menus => [{:id => @website.menus.first.sub_menus.first._id, :name => "Sub Bar"}, {:name => "Sub Apple", :order => 3}]}, {:name => "Apple", :sub_menus => [{:name => "Sub Orange"}]}], :meta_keywords => "foo,bar,apple,orange", :meta_description => "This is a quick meta desc example.")
    response.code.should == "200"

    @website.reload
    @website.home_page_id.should == @page._id
    @website.name.should == "Name"
    @website.subdomain.should == "apple"
    @website.domain.should == "http://www.foobar.com"
    @website.width.should == 50
    @website.width_unit.should == "px"
    @website.menu_align.should == Website::RIGHT
    @website.site_align.should == Website::CENTER
    @website.analytics.should be_a_kind_of(Analytics)
    @website.analytics.ga.should == "UA-1234-56"

    @website.favicon_uid.should_not be_nil
    @website.logo_uid.should_not be_nil

    @website.active_style.should == Website::CUSTOM
    @website.css_layout.should == "dark"
    @website.css_base_layout.should == "light"
    @website.custom_css.should == "body {color: red;}"
    @website.css_tags.should == {"text_color" => "#AAA", "text_font" => "Arial", "title_color" => "#AAAAAA", "title_font" => "Helvetica Neue", "menu_text_color" => "rgba(200,99,13,0.51)", "menu_bg_hover" => "rgba(255,255,255,1)"}

    @website.meta_description.should == "This is a quick meta desc example."
    @website.meta_keywords.should == "foo,bar,apple,orange"

    #@website.social.should == {"twitter" => "twitter"}

    @website.menus.should have(2).menus
    menu = @website.menus.first
    menu.name.should == "Apple"
    menu.sub_menus.should have(1).menus
    menu.sub_menus.first.name.should == "Sub Orange"

    menu = @website.menus.last
    menu.name.should == "Bar"
    menu.sub_menus.should have(2).menus
    menu.sub_menus.first.name.should == "Sub Bar"
    menu.sub_menus.first.order.should == 0
    menu.sub_menus.last.name.should == "Sub Apple"
    menu.sub_menus.last.order.should == 3
  end
end