class Usercp::BillingController < Usercp::BaseController
  skip_before_filter :load_website
  before_filter :optional_load_website, :only => [:subscriptions, :show]

  def restart
    if current_user.demo_expires?
      return render :nothing => true, :status => :no_content
    end

    user = current_user
    unless user.subscription and user.subscription.status == "canceled"
      return render :nothing => true, :status => :no_content
    end

    customer = Stripe::Customer.retrieve(user.stripe_id)

    begin
      subscription = customer.update_subscription({:plan => current_user.subscription.plan})
    rescue Stripe::InvalidRequestError => e
      return render :json => {:stripe_error => e.json_body[:error]}, :status => :bad_request
    end

    if subscription.status != "canceled"
      user.subscription.status = subscription.status
      user.save(:validate => false)
    end

    respond_with_model(user, :ok)
  end

  def purchase
    if current_user.demo_expires?
      return render :nothing => true, :status => :no_content
    end

    # General sanity checks
    unless !params[:plan].blank? or !CONFIG[:subscriptions][params[:plan]] or ( user.subscription and params[:plan] == user.subscription.plan )
      return render :nothing => true, :status => :no_content
    end

    user = current_user

    # We need to do an inline email on checkout
    unless params[:email].blank?
      user.email = params[:email]
      return respond_with_model(user, :ok) unless user.valid?
    end

    # Inline website creation
    if !params[:subdomain].blank? and !Website.where(:user_id => user._id).exists?
      website = Website.create(:user => current_user, :subdomain => params[:subdomain])
      return respond_with_model(website, :created) unless website.errors.empty?
    end

    # Now do all the fun things
    # 4242424242424242
    data = {:plan => params[:plan]}
    data[:coupon] = params[:coupon] unless params[:coupon].blank?

    # Existing customer, we can just do a base upgrade
    begin
      if user.stripe_id?
        customer = Stripe::Customer.retrieve(user.stripe_id)
        subscription = customer.update_subscription(data)

      # New customer
      else
        data[:card], data[:description] = params[:token], user._id.to_s

        customer = Stripe::Customer.create(data)
        subscription = customer.subscription

        user.stripe_card = {"last4" => customer.active_card.last4, "type" => customer.active_card.type, "exp_year" => customer.active_card.exp_year, "exp_month" => customer.active_card.exp_month}
        user.stripe_id = customer.id
      end
    rescue Stripe::InvalidRequestError => e
      return render :json => {:stripe_error => e.json_body[:error]}, :status => :bad_request
    end

    #{"cancel_at_period_end":false,"canceled_at":null,"current_period_end":1341367473,"current_period_start":1338775473,"customer":"cus_fD6JjflkddW88l","ended_at":null,"object":"subscription","start":1338775473,"status":"trialing","trial_end":1341367473,"trial_start":1338775473,"plan":{"id":"starter","amount":500,"currency":"usd","interval":"month","livemode":false,"name":"Starter","object":"plan","trial_period_days":30}}
    response = {:status => subscription.status, :period_end => Time.at(subscription.current_period_end).to_date.to_s(:long_ordinal), :cost => subscription.plan.amount, :plan => subscription.plan.id}
    if subscription.status == "trialing"
      response[:trial_end] = Time.at(subscription.trial_end).to_date.to_s(:long_ordinal)
      response[:trial_days] = subscription.plan.trial_period_days
    end

    # Figure out what happened with the subscription
    if user.subscription and CONFIG[:subscriptions][user.subscription.plan][:tier] > CONFIG[:subscriptions][subscription.plan.id][:tier]
      response[:change_type] = :downgrade
    else
      response[:change_type] = :upgrade
    end

    # Update the sync limits
    user.build_subscription unless user.subscription
    user.subscription.plan = subscription.plan.id
    user.subscription.status = subscription.status
    user.subscription.period_end = Time.at(subscription.current_period_end)
    user.subscription.trial_end = subscription.status == "trialing" ? Time.at(subscription.trial_end) : nil

    # Update the sync data if needed
    next_sync = user.feature_limit(:sync_hrs).hours.from_now.utc
    if !user.next_sync or user.next_sync > next_sync
      user.next_sync = next_sync
    end
    user.total_syncs = 0 if response[:change_type] == :upgrade

    user.subscription.check_features
    user.save

    respond_with_model(user, :ok, {:stripe => response, :website => website})
  end

  def subscriptions
    default_kicker
  end

  def cancel_subscription
    if current_user.stripe_id? and current_user.subscription and current_user.subscription.status != "canceled"
      customer = Stripe::Customer.retrieve(current_user.stripe_id)
      customer.cancel_subscription(:at_period_end => true)

      current_user.subscription.status = "canceled"
      current_user.save
    end

    respond_with_model(current_user, :ok)
  end

  def update
    if current_user.demo_expires?
      return render :nothing => true, :status => :no_content
    end

    user = current_user

    begin
      if user.stripe_id?
        customer = Stripe::Customer.retrieve(user.stripe_id)
        customer.card = params[:token]
        customer.save
      else
        customer = Stripe::Customer.create(:card => params[:token], :description => user._id.to_s)
      end
    rescue Stripe::InvalidRequestError => e
      return render :json => {:stripe_error => e.json_body[:error]}, :status => :bad_request
    end

    user.stripe_card = {"last4" => customer.active_card.last4, "type" => customer.active_card.type, "exp_year" => customer.active_card.exp_year, "exp_month" => customer.active_card.exp_month}
    user.stripe_id = customer.id unless user.stripe_id?

    user.save
    respond_with_model(user, :ok)
  end

  def show
    default_kicker
  end
end