class Usercp::UsersController < Usercp::BaseController
  skip_before_filter :load_website, :only => [:unflag, :update, :job_status, :unsubscribe]
  skip_before_filter :require_logged_in, :only => [:unsubscribe]

  def unflag
    if current_user.flags[params[:flag].to_s]
      current_user.unset(:"flags.#{params[:flag]}")
    end

    render :nothing => true, :status => :no_content
  end

  def update
    if params[:updated_at] and params[:updated_at] != current_user.updated_at.strftime("%Y-%m-%dT%H:%M:%SZ")
      return render :nothing => true, :status => :conflict
    end

    user = current_user
    [:email, :full_name, :username, :timezone].each do |key|
      user.send("#{key}=", params[key]) if params.has_key?(key)
    end

    user.receive_emails = params[:receive_emails] == "1"
    user.save
    respond_with_model(user, :ok)
  end

  def job_status
    # We're also doing an initial queue
    if params[:queue] == "1" and !current_user.syncing and current_user.can_resync?
      if current_user.provider == "flickr"
        klass = Job::Flickr::Album
      elsif current_user.provider == "smugmug"
        klass = Job::Smugmug::Album
      end

      uuid = klass.create_to(current_user.feature_limit(:queue), :user_id => current_user._id)
      current_user.jobs["album"] = uuid
      current_user.set("jobs.album" => uuid, "total_syncs" => current_user.total_syncs + 1)
    end

    # Loading all the media (important)
    if current_user.jobs["media"]
      return media_status

    # Loading the album list (more important)
    elsif current_user.jobs["album"]
      data = Resque::Plugins::Status::Hash.get(current_user.jobs["album"])
      unless data
        current_user.unset(:"jobs.album")
        current_user.jobs.delete("album")
        return render :json => {:albums => current_user.albums.sort(:_id), :user => current_user}
      end

      # Critical failure
      if data["status"] == "failed"
        current_user.unset(:"jobs.album")
        current_user.jobs.delete("album")
        return render :json => {:loading => true, :status => :error}

      # Done, figure out what's going on with media
      elsif data["status"] == "completed"
        current_user.unset(:"jobs.album")
        current_user.jobs.delete("album")
        return media_status

      # General status
      elsif data["status"] == "working"
        return render :json => {:loading => true, :status => :albums, :album => data["album"]}

      # Queued still
      else
        return render :json => {:loading => true, :status => :queued_albums}
      end
    end

    render :json => current_user.albums.sort(:_id)
  end

  def edit
    default_kicker
  end

  def sync
    default_kicker
  end

  # Quick unsubscribing via emails
  def unsubscribe
    user = User.where(:_id => params[:user_id].to_s, :email_token => params[:email_token].to_s).only(:receive_emails).first
    unless user
      return redirect_to websites_path, :alert => t("usercp.users.unsubscribe.no_auth")
    end

    user.set(:receive_emails => false)
    redirect_to edit_users_path, :alert => t("usercp.users.unsubscribe.done")
  end

  private
  def media_status
    data = Resque::Plugins::Status::Hash.get(current_user.jobs["media"])
    unless data
      if current_user.jobs["media"]
        current_user.unset(:"jobs.media")
        current_user.jobs.delete("media")
      end

      return render :json => {:albums => current_user.albums.sort(:_id), :user => current_user}
    end

    # Critical failure
    if data["status"] == "failed"
      current_user.unset(:"jobs.album")
      current_user.unset(:"jobs.media")
      return render :json => {:loading => true, :status => :error}

    # Done, return updated albums
    elsif data["status"] == "completed"
      current_user.unset(:"jobs.album")
      current_user.unset(:"jobs.media")
      current_user.jobs.delete("media")
      current_user.jobs.delete("album")
      return render :json => {:albums => current_user.albums.sort(:_id), :user => current_user}

    # General status
    elsif data["status"] == "working"
      res = {:loading => true, :status => data["area"]}
      if data["total"] and data["num"]
        res[:total], res[:loaded] = data["total"], data["num"]
        res[:progress] = res[:loaded] / res[:total].to_f
      end

      return render :json => res
    end

    # Queued still
    return render :json => {:loading => true, :status => :queued_media}
  end
end