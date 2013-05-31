require "spec_helper"

describe Usercp::PagesController do
  before :all do
    @user = create(:flickr_user, :subscription => build(:subscription))
    @website = create(:website, :user => @user, :menus => [build(:menu, :sub_menus => [build(:sub_menu)])])
  end

  before :each do
    request.session[:user_id] = @user._id
    request.cookie_jar.signed[:remember_token] = @user.remember_token
  end

  context "add attributes to page" do
    before :all do
      @controller = Usercp::PagesController.new
    end

    it "adds the basic attributes" do
      page = StaticPage.new
      @controller.stub(:params).and_return(HashWithIndifferentAccess.new(:status => Page::PUBLIC.to_s, :slug => "slug", :name => "name", :title => "title", :password => "password", :password_confirmation => "password", :body => "body"))
      @controller.send(:add_attributes, page)

      page.status.should == Page::PUBLIC
      page.slug.should == "slug"
      page.name.should == "name"
      page.title.should == "title"
      page.password.should == "password"
      page.password_confirmation.should == "password"
      page.body.should == "body"
    end

    it "sanitizes html" do
      page = StaticPage.new
      @controller.stub(:params).and_return(HashWithIndifferentAccess.new(:name => "<b>name</b>", :title => "<b>title</b>", :password => "<b>password</b>", :password_confirmation => "<b>password</b>", :body => "<b>Foo Bar</b><script>Test</script>"))
      @controller.send(:add_attributes, page)

      page.name.should == "&lt;b&gt;name&lt;/b&gt;"
      page.title.should == "&lt;b&gt;title&lt;/b&gt;"
      page.password.should == "<b>password</b>"
      page.password_confirmation.should == "<b>password</b>"
      page.body.should == "<b>Foo Bar</b>Test"
    end

    context "adds by type" do
      it "for about" do
        picture = fixture_file_upload(Rails.root.join("spec", "media", "image.png"), "image/png")

        page = AboutPage.new
        page.should_receive(:picture=).with(picture)

        @controller.stub(:current_user).and_return(@user)
        @controller.stub(:params).and_return(HashWithIndifferentAccess.new(:pic_side => AboutPage::LEFT.to_s, :picture => picture))
        @controller.send(:add_attributes, page)

        page.pic_side.should == AboutPage::LEFT
      end

      it "for contact" do
        page = ContactPage.new(:fields => [PageField.new(:name => "Foo")])

        @controller.stub(:params).and_return(HashWithIndifferentAccess.new(:send_to => "foo@bar.com", :thanks_text => "Thanks!", :fields => {page.fields.first.id => {:name => "name", :placeholder => "placeholder", :required => "1", :input_type => :text_field}, "1" => {}, "2" => {:name => "new-name", :input_type => "text_area"}}))
        @controller.send(:add_attributes, page)

        page.send_to.should == "foo@bar.com"
        page.thanks_text.should == "Thanks!"

        page.fields.should have(3).fields
        field = page.fields.first
        field.name.should == "name"
        field.placeholder.should == "placeholder"
        field.required.should be_true
        field.input_type.should == "text_field"

        field = page.fields.second
        field._id.should == "1"
        field.name.should be_nil

        field = page.fields.third
        field._id.should be_a_kind_of(BSON::ObjectId)
        field.name.should == "new-name"
        field.placeholder.should be_nil
        field.required.should be_false
        field.input_type.should == "text_area"
      end

      it "for media carousel" do
        page = MediaCarouselPage.new

        @controller.stub(:params).and_return(HashWithIndifferentAccess.new(:timer => "2", :randomize => "1"))
        @controller.send(:add_attributes, page)

        page.timer.should == 2
        page.randomize.should be_true
      end

      it "for media row" do
        page = MediaRowPage.new

        @controller.stub(:params).and_return(HashWithIndifferentAccess.new(:grow_in => MediaRowPage::VERTICAL.to_s))
        @controller.send(:add_attributes, page)

        page.grow_in = MediaRowPage::VERTICAL
      end

      it "for a media page" do
        album = create(:album, :user => @user)
        bad_album = create(:album)

        [MediaCarouselPage, MediaRowPage, MediaGridPage].each do |klass|
          page = klass.new

          @controller.stub(:current_user).and_return(@user)
          @controller.stub(:params).and_return(HashWithIndifferentAccess.new(:per_page => "3", :max_media => "4", :max_size => "300", :sort_by_key => "title", :sort_by_mode => "desc", :album_ids => [album._id.to_s, BSON::ObjectId.new.to_s, bad_album._id.to_s]))
          @controller.send(:add_attributes, page)

          page.per_page.should == 3
          page.max_media.should == 4
          page.max_size.should == 300
          page.album_ids.should == [album._id]
          page.sort_by.should == [["title", "desc"]]
        end
      end

      it "for redirect" do
        page = RedirectPage.new
        @controller.stub(:params).and_return(HashWithIndifferentAccess.new(:location => "http://foobar.com"))
        @controller.send(:add_attributes, page)
        page.location.should == "http://foobar.com"
      end
    end
  end

  context "create" do
    it "without error" do
      post(:create, {:type => "static", :status => Page::PRIVATE, :slug => "new-slug", :name => "Foo Bar", :title => "Foo Bar", :password => "123456", :password_confirmation => "123456", :body => "<b>Foo Bar</b>"})
      response.code.should == "201"

      page = Page.find(JSON.parse(response.body)["id"])
      page.should be_a_kind_of(StaticPage)
      page.status.should == Page::PRIVATE
      page.slug.should == "new-slug"
      page.name.should == "Foo Bar"
      page.title.should == "Foo Bar"
      page.body.should == "<b>Foo Bar</b>"

      password = BCrypt::Password.new(page.encrypted_password)
      password.should == "123456"
    end

    #it "errors if page needs a subscription" do
    #  user = create(:flickr_user)
    #  website = create(:website, :user => user)
    #
    #  request.session[:user_id] = user._id
    #  post(:create, {:type => "mediacarousel"})
    #  response.code.should == "402"
    #end

    context "types" do
      it "errors if invalid" do
        post(:create, {:type => "foobar"})
        response.code.should == "204"
      end

      [["about", AboutPage], ["contact", ContactPage], ["redirect", RedirectPage], ["mediacarousel", MediaCarouselPage], ["mediagrid", MediaGridPage], ["mediarow", MediaRowPage], ["static", StaticPage]].each do |type, klass|
        it "creates a #{type} page" do
          Usercp::PagesController.any_instance.should_receive(:add_attributes) do |page|
            page.should be_a_kind_of(klass)
          end

          post(:create, {:type => type})
        end
      end
    end
  end

  context "update" do
    it "if the page exists" do
      page = create(:static_page, :user => @user, :website => @website)
      put(:update, {:id => page._id, :status => Page::PUBLIC, :slug => "update-slug", :name => "Foo Bar", :title => "Foo Bar", :password => "123456", :password_confirmation => "123456", :body => "<b>Foo Bar</b>"})
      response.code.should == "200"

      page.reload
      page.status.should == Page::PUBLIC
      page.slug.should == "update-slug"
      page.name.should == "Foo Bar"
      page.title.should == "Foo Bar"
      page.body.should == "<b>Foo Bar</b>"

      password = BCrypt::Password.new(page.encrypted_password)
      password.should == "123456"
    end

    it "unless the page does't exist" do
      page = create(:page, :user => @user, :website => build(:website))
      put(:update, {:id => page._id})
      response.code.should == "204"
    end

    it "unless changed" do
      page = create(:static_page, :user => @user, :website => @website)
      put(:update, {:id => page.id, :updated_at => 5.minutes.from_now.utc})
      response.code.should == "409"
    end

    #it "errors if page needs a subscription" do
    #  page = create(:page, :user => @user, :website => @website)
    #  put(:update, {:id => page._id})
    #  response.code.should == "402"
    #end
  end

  it "deletes a page" do
    page = create(:page, :user => @user, :website => @website)

    delete(:destroy, {:id => page._id})
    response.code.should == "204"

    lambda { page.reload }.should raise_error(MongoMapper::DocumentNotFound)
  end
end