class Usercp::PagesController < Usercp::BaseController
  def create
    if params[:type] == "about"
      page = AboutPage.new
    elsif params[:type] == "contact"
      page = ContactPage.new
    elsif params[:type] == "redirect"
      page = RedirectPage.new
    elsif params[:type] == "mediacarousel"
      page = MediaCarouselPage.new
    elsif params[:type] == "mediagrid"
      page = MediaGridPage.new
    elsif params[:type] == "mediarow"
      page = MediaRowPage.new
    elsif params[:type] == "static"
      page = StaticPage.new
    else
      return render :nothing => true, :status => :no_content
    end

    unless current_user.has_feature?(params[:type])
      return render :nothing => true, :status => :payment_required
    end

    page.user = current_user
    page.website = @website
    add_attributes(page)

    page.save
    respond_with_model(page, :created)
  end

  def update
    page = @website.pages.where(:_id => params[:id].to_s).first
    return render :nothing => true, :status => :no_content unless page

    if params[:updated_at] and params[:updated_at] != page.updated_at.strftime("%Y-%m-%dT%H:%M:%SZ")
      return render :nothing => true, :status => :conflict
    end

    unless current_user.has_feature?(page.type)
      return render :nothing => true, :status => :payment_required
    end

    add_attributes(page)

    page.save
    respond_with_model(page, :ok)
  end

  def destroy
    page = @website.pages.where(:_id => params[:id].to_s).first
    if page
      if @website.home_page_id == page._id
        home = Page.where(:website_id => @website._id).public.only(:_id).first
        @website.home_page_id = home ? home._id : nil
      end

      @website.menus.each do |menu|
        menu.page_id = nil if menu.page_id == page._id

        menu.sub_menus.each do |sub|
          sub.page_id = nil if sub.page_id == page._id
        end
      end

      @website.save(:validate => false)

      page.destroy
    end

    render :nothing => true, :status => :no_content
  end

  private
  def add_attributes(page)
    page.status = params[:status].to_i
    page.slug = params[:slug]
    page.name = params[:name].blank? ? nil : CGI::escapeHTML(params[:name])
    page.title = params[:title].blank? ? nil : CGI::escapeHTML(params[:title])

    if params[:password] != "**********" and params[:password_confirmation] != "**********"
      if params[:password].blank? and params[:password_confirmation].blank?
        page.encrypted_password = nil
      else
        page.password = params.delete(:password)
        page.password_confirmation = params.delete(:password_confirmation)
      end
    end

    # Sanitize the body so they don't do something we don't want
    filters = {
      :elements => Sanitize::Config::RELAXED[:elements],
      :attributes => {
        :all         => ["dir", "lang", "title", "style", "class"],
        "a"          => ["href"],
        "blockquote" => ["cite"],
        "col"        => ["span", "width"],
        "colgroup"   => ["span", "width"],
        "del"        => ["cite", "datetime"],
        "img"        => ["align", "alt", "height", "src", "width"],
        "ins"        => ["cite", "datetime"],
        "ol"         => ["start", "reversed", "type"],
        "q"          => ["cite"],
        "table"      => ["summary", "width"],
        "td"         => ["abbr", "axis", "colspan", "rowspan", "width"],
        "th"         => ["abbr", "axis", "colspan", "rowspan", "scope", "width"],
        "time"       => ["datetime", "pubdate"],
        "ul"         => ["type"]
      },
      :allow_comments => false,
      :add_attributes => Sanitize::Config::BASIC[:add_attributes],
      :protocols => Sanitize::Config::RELAXED[:protocols]
    }

    page.body = params[:body].blank? ? nil : Sanitize.clean(params[:body].gsub("\n", "<br>"), filters)

    # Any page specific config
    if page.is_a?(AboutPage)
      page.pic_side = params[:pic_side].to_i

      unless current_user.demo_expires?
        page.picture = params[:picture] if params[:picture]
        page.remove_picture = params[:remove_picture] == "1"
      end

    elsif page.is_a?(ContactPage)
      page.send_to = params[:send_to]
      page.thanks_text = params[:thanks_text].blank? ? nil : CGI::escapeHTML(params[:thanks_text])

      used_fields = {}
      page.fields.each {|f| used_fields[f._id.to_s] = f}

      page.fields = []
      if params[:fields]
        (params[:fields].is_a?(Hash) ? params[:fields].values : params[:fields])
        list = params[:fields]
        if params[:fields].is_a?(Hash)
          list = list.map {|k, v| v[:id] = k; v}
        end

        list.each do |data|
          if data[:id] and used_fields[data[:id]]
            page.fields.push(used_fields[data[:id]])
            field = used_fields[data[:id]]
          else
            field = page.fields.build(:_id => data[:id])
          end

          field.name = data[:name].blank? ? nil : CGI::escapeHTML(data[:name])
          field.required = data[:required] == "1"
          field.input_type = data[:input_type]
          field.placeholder = data[:placeholder].blank? ? nil : CGI::escapeHTML(data[:placeholder])

          if data[:id] and !used_fields[data[:id]] and field.valid?
            field._id = BSON::ObjectId.new
          end
        end
      end

    elsif page.is_a?(RedirectPage)
      page.location = params[:location].blank? ? nil : Sanitize.clean(params[:location])

    elsif page.is_a?(MediaCarouselPage)
      page.timer = params[:timer].to_i
      page.randomize = params[:randomize].to_i == 1

    elsif page.is_a?(MediaRowPage)
      page.grow_in = params[:grow_in].to_i

    end

    # Generic media page config
    if page.kind_of?(MediaPage)
      page.per_page = params[:per_page].to_i
      page.max_media = params[:max_media].to_i
      page.max_media = nil if page.max_media == 0
      page.max_size = params[:max_size].to_i

      # Check the album ids quickly
      page.album_ids = []
      if params[:album_ids]
        album_ids = params[:album_ids].reject {|v| !BSON::ObjectId.legal?(v)}
        album_ids.map! {|v| BSON::ObjectId(v)}

        page.album_ids = Album.where(:user_id => current_user._id, :_id.in => album_ids).only(:_id).map {|a| a._id}
      end

      # Manually validate sorting
      if params[:sort_by_key] and params[:sort_by_mode]
        if Media::SORTABLE[params[:sort_by_key]] and params[:sort_by_mode] == "asc" or params[:sort_by_mode] == "desc"
          page.sort_by = [[params[:sort_by_key], params[:sort_by_mode]]]
        end
      end
    end
  end
end