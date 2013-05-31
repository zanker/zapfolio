class SubscriptionsController < ApplicationController
  def show
    if user_signed_in? and !current_user.demo_expires?
      return redirect_to billing_subscription_path
    end
  end
end