class SessionsController < ApplicationController
  before_filter :require_non_demo_logged_out, :except => :destroy
  before_filter :require_logged_in, :only => :destroy

  def create
    if !CONFIG[:oauth][params[:provider]]
      return redirect_to new_session_path, :alert => t("sessions.create.bad_provider", :provider => params[:provider].to_s)
    elsif !env["omniauth.auth"] or !env["omniauth.auth"].valid?
      return redirect_to new_session_path, :alert => t("sessions.create.bad_login", :email => view_context.mail_to(CONFIG[:contact][:email]))
    end

    omniauth = env["omniauth.auth"]
    remember_token = SecureRandom.base64(60).tr("+/=", "pqr")

    user = User.where(:provider => omniauth.provider, :uid => omniauth.uid.to_s).only(:current_sign_in_ip, :current_sign_in_at, :analytics_id).first
    if user
      user.set(:remember_token => remember_token, :current_sign_in_ip => request.ip, :current_sign_in_at => Time.now.utc, :last_sign_in_at => user.current_sign_in_at)

    # Create a new account for them silently
    else
      new_account = true

      user = User.new
      user.provider = omniauth.provider
      user.uid = omniauth.uid
      user.username = omniauth.info.name
      user.flags["intro"] = true
      user.email = omniauth.info.email unless omniauth.info.email.blank?
      user.oauth = {"token" => omniauth.credentials.token, "secret" => omniauth.credentials.secret}
      user.remember_token = remember_token
      user.current_sign_in_ip = request.ip
      user.current_sign_in_at = Time.now.utc

      # Any provider specific data
      if omniauth.provider == "flickr"
        user.full_name = omniauth.info.nickname unless omniauth.info.nickname.blank?
        user.timezone = omniauth.extra.raw_info.person.timezone.offset if omniauth.extra.raw_info.person.timezone
        user.provider_sub = {:pro => omniauth.info.ispro == 1}

      elsif omniauth.provider == "smugmug"
        user.provider_sub = {:sub => omniauth.extra.user_hash["AccountType"], :status => omniauth.extra.user_hash["AccountStatus"], :vault => omniauth.extra.user_hash["SmugVault"]}
      end

      # Move over the analytics id into the user model too
      if cookies.signed[:aid]
        user.analytics_id = cookies.signed[:aid]
      end

      user.save(:validate => false)

      if omniauth.provider == "flickr"
        uuid = Job::Flickr::Album.create(:user_id => user._id)
      elsif omniauth.provider == "smugmug"
        uuid = Job::Smugmug::Album.create(:user_id => user._id)
      end

      user.set("jobs.album" => uuid)
    end

    reset_session

    session[:user_id] = user._id.to_s
    cookies.permanent.signed[:provider] = {:value => omniauth.provider, :httponly => true}
    cookies.permanent.signed[:remember_token] = {:value => remember_token, :httponly => true}
    cookies.permanent.signed[:aid] = user.analytics_id

    cookies.delete(:isdemo) if cookies[:isdemo]

    if env["omniauth.origin"] =~ %r{^/admin/subscription/checkout}
      redirect_to env["omniauth.origin"], :notice => t("sessions.create.logged_in_sub")
    elsif new_account
      redirect_to setup_path
    elsif env["omniauth.origin"] and env["omniauth.origin"] =~ %r{^/}
      redirect_to env["omniauth.origin"], :notice => t("sessions.create.logged_in")
    else
      redirect_to websites_path, :notice => t("sessions.create.logged_in")
    end
  end

  def destroy
    if current_user.demo_expires?
      current_user.set(:demo_expires => Time.now.utc)
    end

    current_user.unset(:remember_token)
    reset_session

    redirect_to root_path, :notice => t("sessions.destroy.success")
  end

  def failure
    redirect_to new_session_path, :alert => t("sessions.failure.#{params[:message].to_s}", :default => t("sessions.failure.generic", :message => params[:message].humanize))
  end

  def new
  end
end