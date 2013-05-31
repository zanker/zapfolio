class HomeController < ApplicationController
  def no_site
    render :status => :not_found
  end

  def not_setup
    @website = Website.where(:_id => params[:website_id].to_s).first
  end

  def terms_conditions

  end

  def privacy_policy

  end

  def show

  end
end