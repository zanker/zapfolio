# https://stripe.com/docs/api#list_events
class StripeController < ApplicationController
  skip_before_filter :authenticate_user
  skip_before_filter :verify_authenticity_token

  before_filter do |r|
    unless r.params[:webhook_key] == CONFIG[:stripe][:webhook_key]
      return render_404
    end
  end

  # Dispatch to the other methods for sanity
  def event
    # Short circuit ping
    if params[:type] == "ping"
      return render :nothing => true, :status => :ok
    end

    # Pull from server for security
    event = Stripe::Event.retrieve(params[:id])
    unless event.type == params[:type]
      return render :nothing => true, :status => :ok
    end

    if event.type == "customer.subscription.created"
      customer_subscription_created(event)
    elsif event.type == "customer.subscription.updated"
      customer_subscription_updated(event)
    elsif event.type == "customer.subscription.deleted"
      customer_subscription_deleted(event)
    elsif event.type == "customer.subscription.trial_will_end"
      customer_subscription_trial_will_end(event)
    elsif event.type == "invoice.payment_succeeded"
      invoice_payment_succeeded(event)
    elsif event.type == "invoice.payment_failed"
      invoice_payment_failed(event)
    end

    render :nothing => true, :status => :ok
  end

  private
  # Handling the actual subscription plan changing
  def customer_subscription_created(event)
    user = User.where(:stripe_id => event.data.object.customer).first
    return unless user

    user.build_subscription unless user.subscription
    user.subscription.plan = event.data.object.plan.id
    user.subscription.status = event.data.object.cancel_at_period_end ? "canceled" : event.data.object.status
    user.subscription.period_end = Time.at(event.data.object.current_period_end)
    user.subscription.started = Time.at(event.data.object.start)
    user.subscription.period_start = Time.at(event.data.object.current_period_start)
    user.subscription.canceled_at = event.data.object.canceled_at ? Time.at(event.data.object.canceled_at) : event.data.object.canceled_at

    user.subscription.trial_end = nil
    if event.data.object.status == "trialing"
      user.subscription.trial_end = Time.at(event.data.object.trial_end)
    end

    user.subscription.check_features
    user.save(:validate => false)

    user
  end

  def customer_subscription_updated(event)
    customer_subscription_created(event)
  end

  def customer_subscription_deleted(event)
    user = User.where(:stripe_id => event.data.object.customer).only(:subscription).first
    return unless user

    user.subscription.strip_features
    user.unset(:subscription)
  end

  # Email triggers
  def customer_subscription_trial_will_end(event)
    user = User.where(:stripe_id => event.data.object.customer).only(:_id).first
    return unless user

    Notification.trial_will_end(user._id.to_s).deliver
  end

  def invoice_payment_succeeded(event)
    user = User.where(:stripe_id => event.data.object.customer).only(:_id).first
    return unless user

    if event.data.object.total > 0
      Notification.invoice_payment_succeeded(user._id.to_s, {"total" => event.data.object.total / 100.0}).deliver
    end
  end

  def invoice_payment_failed(event)
    user = User.where(:stripe_id => event.data.object.customer).only(:_id).first
    return unless user

    Notification.invoice_payment_failed(user._id.to_s, {"total" => event.data.object.total / 100.0}).deliver
  end
end