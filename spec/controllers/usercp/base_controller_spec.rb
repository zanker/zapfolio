require "spec_helper"

describe Usercp::BaseController do
  before :all do
    @user = create(:flickr_user, :subscription => build(:subscription))
  end

  before :each do
    request.session[:user_id] = @user._id
    request.cookie_jar.signed[:remember_token] = @user.remember_token
  end

  it "finds the default website" do
    website = create(:website, :user => @user)

    controller = Usercp::BaseController.new
    controller.should_receive(:current_user).and_return(@user)
    controller.send(:load_website)
    controller.instance_variable_get(:@website).should == website
  end

  it "redirects to the index if no website is found" do
    controller = Usercp::BaseController.new
    controller.should_receive(:current_user).and_return(mock("User", :_id => nil))
    controller.should_receive(:setup_path)
    controller.should_receive(:redirect_to)
    controller.send(:load_website)
  end

  it "responds with a json error on model error" do
    website = build(:website, :width => 5000, :menus => [build(:menu, :name => nil, :sub_menus => [build(:sub_menu, :name => nil)])])
    website.valid?

    controller = Usercp::BaseController.new
    controller.should_receive(:render).with(:json => {:errors => {:menus => {website.menus.first._id => {:name => ["is too short (minimum is 1 characters)"], :sub_menus => {website.menus.first.sub_menus.first._id => {:name => ["is too short (minimum is 1 characters)"]}}}}, :width => ["must be less than or equal to 100"]}, :attributes => {:menus => "Menus", :width => "Width", :name => "Name", :sub_menus => "Sub menus"}, :scope => "website"}, :status => :bad_request)
    controller.send(:respond_with_model, website)
  end

  it "responds with the json form of the model" do
    website = build(:website)

    controller = Usercp::BaseController.new
    controller.should_receive(:render).with(:json => website, :status => :ok)
    controller.send(:respond_with_model, website)
  end
end