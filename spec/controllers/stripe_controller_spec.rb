require "spec_helper"

describe StripeController do
  before :each do
    User.delete_all(:stripe_id => "cus_aA1mvC5xCILOB0")
    @user = build(:flickr_user, :stripe_id => "cus_aA1mvC5xCILOB0", :email => "staticemail@zapfol.io")
    request.session[:user_id] = @user._id
    request.cookie_jar.signed[:remember_token] = @user.remember_token
  end

  it "syncs customer data on a customer.subscription.created event" do
    @user.save
    website = create(:website, :user => @user)

    Stripe.should_receive(:request).with(any_args).and_return([Responses::STRIPE["customer.subscription.created"], ""])
    post(:event, {:webhook_key => CONFIG[:stripe][:webhook_key], :id => Responses::STRIPE["customer.subscription.created"]["id"], :type => Responses::STRIPE["customer.subscription.created"]["type"]})
    response.code.should == "200"

    @user.reload
    @user.stripe_id.should == "cus_aA1mvC5xCILOB0"
    @user.email.should == "staticemail@zapfol.io"

    @user.subscription.should_not be_nil
    @user.subscription.plan.should == "starter"
    @user.subscription.status.should == "trialing"
    @user.subscription.period_start.should == Time.at(Responses::STRIPE["customer.subscription.created"]["data"]["object"]["current_period_start"])
    @user.subscription.period_end.should == Time.at(Responses::STRIPE["customer.subscription.created"]["data"]["object"]["current_period_end"])
    @user.subscription.trial_end.should == Time.at(Responses::STRIPE["customer.subscription.created"]["data"]["object"]["trial_end"])
    @user.subscription.started.should == Time.at(Responses::STRIPE["customer.subscription.created"]["data"]["object"]["start"])
    @user.subscription.canceled_at.should be_nil

    website.reload
    website.domain_paid.should be_true
    website.seo_paid.should_not be_true
    website.brand_paid.should_not be_true
  end

  it "syncs customer data on a customer.subscription.updated event" do
    @user.save

    StripeController.any_instance.should_receive(:customer_subscription_created)
    post(:event, {:webhook_key => CONFIG[:stripe][:webhook_key], :id => Responses::STRIPE["customer.subscription.updated"]["id"], :type => Responses::STRIPE["customer.subscription.updated"]["type"]})
    response.code.should == "200"
  end

  it "removes a subscription on a customer.subscription.deleted event" do
    @user.build_subscription(:plan => "starter")
    @user.save

    website = create(:website, :user => @user, :domain_paid => true)

    Stripe.should_receive(:request).with(any_args).and_return([Responses::STRIPE["customer.subscription.deleted"], ""])
    post(:event, {:webhook_key => CONFIG[:stripe][:webhook_key], :id => Responses::STRIPE["customer.subscription.deleted"]["id"], :type => Responses::STRIPE["customer.subscription.deleted"]["type"]})
    response.code.should == "200"

    @user.reload
    @user.subscription.should be_nil

    website.reload
    website.domain_paid.should_not be_true
    website.seo_paid.should_not be_true
    website.brand_paid.should_not be_true
  end

  it "sends a trial ending email on a customer.subscription.trial_will_end event" do
    @user.save

    Stripe.should_receive(:request).with(any_args).and_return([Responses::STRIPE["customer.subscription.trial_will_end"], ""])
    post(:event, {:webhook_key => CONFIG[:stripe][:webhook_key], :id => Responses::STRIPE["customer.subscription.trial_will_end"]["id"], :type => Responses::STRIPE["customer.subscription.trial_will_end"]["type"]})
    response.code.should == "200"

    ActionMailer::Base.deliveries.should have(1).email
  end

  it "sends a payment received email on a invoice.payment_succeeded event" do
    @user.build_subscription(:plan => "starter")
    @user.save

    Stripe.should_receive(:request).with(any_args).and_return([Responses::STRIPE["invoice.payment_succeeded"], ""])
    post(:event, {:webhook_key => CONFIG[:stripe][:webhook_key], :id => Responses::STRIPE["invoice.payment_succeeded"]["id"], :type => Responses::STRIPE["invoice.payment_succeeded"]["type"]})
    response.code.should == "200"

    ActionMailer::Base.deliveries.should have(1).email
  end

  it "sends a payment failed email on a invoice.payment_failed event" do
    @user.build_subscription(:plan => "starter")
    @user.save

    Stripe.should_receive(:request).with(any_args).and_return([Responses::STRIPE["invoice.payment_failed"], ""])
    post(:event, {:webhook_key => CONFIG[:stripe][:webhook_key], :id => Responses::STRIPE["invoice.payment_failed"]["id"], :type => Responses::STRIPE["invoice.payment_failed"]["type"]})
    response.code.should == "200"

    ActionMailer::Base.deliveries.should have(1).email
  end
end