class Usercp::DashboardController < Usercp::BaseController
  skip_before_filter :load_website

  def setup
    if Website.where(:user_id => current_user._id).exists?
      return redirect_to websites_path
    end

    respond_with do |format|
      format.html { render :kicker }
    end
  end
end