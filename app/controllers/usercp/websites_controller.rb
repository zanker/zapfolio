class Usercp::WebsitesController < Usercp::BaseController
  skip_before_filter :load_website, :only => [:create]
  respond_to :html, :json

  def update
    if params[:updated_at] and params[:updated_at] != @website.updated_at.strftime("%Y-%m-%dT%H:%M:%SZ")
      return render :nothing => true, :status => :conflict
    end

    if current_user.has_feature?(:domain) and !current_user.demo_expires?
      @website.domain = params[:domain].blank? ? nil : params[:domain]
    end

    @website.home_page_id = BSON::ObjectId.legal?(params[:home_page_id]) ? BSON::ObjectId(params[:home_page_id]) : nil
    @website.name = params[:name].blank? ? nil : CGI::escapeHTML(params[:name])
    @website.subdomain = params[:subdomain] unless current_user.demo_expires?
    @website.width = params[:width].to_i
    @website.width_unit = params[:width_unit]
    @website.menu_align = params[:menu_align].to_i
    @website.site_align = params[:site_align].to_i
    @website.css_layout = params[:css_layout]
    @website.css_base_layout = params[:css_base_layout]
    @website.active_style = params[:active_style]

    if current_user.has_feature?(:seo)
      @website.meta_keywords = params[:meta_keywords].blank? ? nil : CGI::escapeHTML(params[:meta_keywords])
      @website.meta_description = params[:meta_description].blank? ? nil : CGI::escapeHTML(params[:meta_description])
    end

    if current_user.has_feature?(:analytics)
      if params[:analytics] and !params[:analytics][:ga].blank?
        @website.build_analytics(:ga => params[:analytics][:ga])
      else
        @website.analytics = nil
      end
    end

    unless current_user.demo_expires?
      @website.favicon = params[:favicon] if params[:favicon]
      @website.remove_favicon = params[:remove_favicon] == "1"

      @website.logo = params[:logo] if params[:logo]
      @website.remove_logo = params[:remove_logo] == "1"
    end

    #@website.social = {}
    #@website.social["twitter"] = params[:social][:twitter] if params[:social][:twitter]
    #@website.social["fb"] = params[:social][:fb] if params[:social][:fb]

    if current_user.has_feature?(:skinning)
      @website.custom_css = params[:custom_css]
    end

    if params[:css_tags].is_a?(Hash) and current_user.has_feature?(:basic_css)
      fonts = {"Arial" => true, "Helvetica" => true, "Georgia" => true, "Helvetica Neue" => true, "Times New Roman" => true}

      @website.css_tags = {}

      CONFIG[:layout_vars].each do |key|
        data = params[:css_tags][key]
        next if data.blank?

        if key =~ /_font$/
          next unless fonts[data]
          @website.css_tags[key] = data
        else
          unless data =~ /^(#([0-9a-z]{3}|[0-9a-z]{6})|rgba\([0-9]{1,3},[0-9]{1,3},[0-9]{1,3},[0-9]+(\.[0-9]+)?\))$/i
            next
          end

          @website.css_tags[key] = data
        end
      end
    end

    # Update the menus
    if params[:menus].is_a?(Array)
      menus = {}
      @website.menus.each {|m| menus[m._id.to_s] = m}
      @website.menus.clear

      params[:menus].each do |data|
        if data[:id] and menus[data[:id]]
          menu = menus[data[:id]]
          @website.menus.push(menu)
        else
          menu = @website.menus.build
        end

        menu.order = data[:order].to_i
        menu.name = data[:name].blank? ? nil : CGI::escapeHTML(data[:name])
        menu.page_id = BSON::ObjectId.legal?(data[:page_id]) ? BSON::ObjectId(data[:page_id]) : nil
        menu.opened = data[:opened] == "1"

        next unless data[:sub_menus].is_a?(Array)

        # Rebuild the sub menus
        sub_menus = {}
        menu.sub_menus.each {|s| sub_menus[s._id.to_s] = s}

        menu.sub_menus.clear
        data[:sub_menus].each do |sub_data|
          if sub_data[:id] and sub_menus[sub_data[:id]]
            sub_menu = sub_menus[sub_data[:id]]
            menu.sub_menus.push(sub_menu)
          else
            sub_menu = menu.sub_menus.build
          end

          sub_menu.order = sub_data[:order].to_i
          sub_menu.name = sub_data[:name].blank? ? nil : CGI::escapeHTML(sub_data[:name])
          sub_menu.page_id = BSON::ObjectId.legal?(sub_data[:page_id]) ? BSON::ObjectId(sub_data[:page_id]) : nil
        end
      end
    end

    @website.cache_bust["gen"] = SecureRandom.hex(4)
    @website.save
    respond_with_model(@website, :ok)
  end

  def create
    if Website.where(:user_id => current_user._id).exists?
      return render :nothing => true, :status => :no_content
    end

    website = Website.new
    website.user = current_user
    website.subdomain = params[:website][:subdomain]
    website.name = params[:website][:subdomain].titleize

    website.save

    if website.valid?
      # Create the starter bits
      page = StaticPage.new(:status => Page::PUBLIC, :name => "Home", :title => "Welcome", :slug => "home", :body => "This is an example of a static home page for your website.<br><br>You can use various HTML tags, such as <b>bold</b>, <i>italics</i>, <span style='color: orange;'>colors</span> and even links, <a href='http://google.com'>http://google.com</a>.<br><br>Feel free to delete this page or overwrite it, it's only here as an example.", :website => website, :user => current_user)
      page.save(:validate => false)

      website.home_page_id = page._id

      page = AboutPage.new(:status => Page::PUBLIC, :name => "About Me", :title => "About Me", :slug => "about", :body => "You can fill this page in however you want. Perhaps general information about yourself, or the work you do?", :website => website, :user => current_user)
      page.save(:validate => false)

      website.menus.build(:order => 0, :name => "About", :page => page)

      page = ContactPage.new(:status => Page::PUBLIC, :name => "Contact", :title => "Contact", :slug => "contact", :website => website, :user => current_user, :send_to => current_user.email)
      page.fields.build(:name => "Your name", :input_type => "text_field", :placeholder => "John Doe")
      page.fields.build(:name => "Message", :input_type => "text_area", :placeholder => "We are having a wedding on the 20th...", :required => true)
      page.save(:validate => false)

      website.menus.build(:order => 0, :name => "Contact", :page => page)

      website.save(:validate => false)
    end

    respond_with_model(website, :created)
  end

  def show
    default_kicker
  end
end