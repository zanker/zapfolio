require "spec_helper"

describe Usercp::BillingController do
  before :each do
    # Hard coded for Ephemeral Response caching
    User.delete(BSON::ObjectId("4fcc34dd6794dc0894000001"))
    @user = build(:flickr_user, :_id => BSON::ObjectId("4fcc34dd6794dc0894000001"))
    request.session[:user_id] = @user._id
    request.cookie_jar.signed[:remember_token] = @user.remember_token

    Website.delete_all(:user_id => @user._id)
  end

  it "purchases a new subscription without a stripe account" do
    @user.save
    website = create(:website, :user => @user)

    EphemeralResponse.fixture_set = :billing_new
    creditcard = Stripe::Token.create(:card => {:number => "4242424242424242", :exp_month => 1, :exp_year => Date.today.year + 1, :cvc => 534})

    post(:purchase, {:plan => "starter", :token => creditcard.id})
    response.code.should == "200"

    data = JSON.parse(response.body)
    data["stripe"].should be_a_kind_of(Hash)
    data["stripe"].should include("status" => "trialing", "cost" => 500, "plan" => "starter", "change_type" => "upgrade", "trial_days" => 30)
    data["stripe"]["trial_end"].should_not be_nil
    data["stripe"]["period_end"].should_not be_nil

    trial_end = (Time.now + data["stripe"]["trial_days"].days).to_i

    @user.reload
    @user.subscription.should be_a_kind_of(Subscription)
    @user.subscription.status.should == "trialing"
    @user.subscription.plan.should == "starter"
    @user.subscription.period_end.to_i.should be_within(4.days).of(trial_end)
    @user.subscription.trial_end.to_i.should be_within(4.days).of(trial_end)

    @user.stripe_id.should_not be_nil
    @user.stripe_card.should be_a_kind_of(Hash)
    @user.stripe_card.should == {"last4" => "4242", "type" => "Visa", "exp_year" => Date.today.year + 1, "exp_month" => 1}

    website.reload
    website.domain_paid.should be_true
    website.seo_paid.should_not be_true
    website.brand_paid.should_not be_true
  end

  it "purchases and sets an email/website without a stripe account" do
    @user.email = nil
    @user.save(:validate => false)

    EphemeralResponse.fixture_set = :billing_email_new
    creditcard = Stripe::Token.create(:card => {:number => "4242424242424242", :exp_month => 1, :exp_year => Date.today.year + 1, :cvc => 534})

    post(:purchase, {:plan => "starter", :token => creditcard.id, :email => "foobar@zapfol.io", :subdomain => "foobar"})
    response.code.should == "200"

    @user.reload
    @user.email.should == "foobar@zapfol.io"

    @user.website.should_not be_nil
    @user.website.subdomain.should == "foobar"
    @user.website.domain_paid.should be_true
    @user.website.seo_paid.should_not be_true
    @user.website.brand_paid.should_not be_true
  end

  it "upgrades an existing subscription" do
    website = create(:website, :user => @user, :domain_paid => true)

    EphemeralResponse.fixture_set = :billing_upgrade
    customer = Stripe::Customer.create(:card => {:number => "4242424242424242", :exp_month => 1, :exp_year => Date.today.year + 1, :cvc => 534}, :plan => "starter")

    @user.build_subscription(:plan => "starter")
    @user.next_sync = 6.hours.from_now.utc
    @user.total_syncs = 2
    @user.stripe_card = {"last4" => customer.active_card.last4, "type" => customer.active_card.type, "exp_year" => customer.active_card.exp_year, "exp_month" => customer.active_card.exp_month}
    @user.stripe_id = customer.id
    @user.save

    post(:purchase, {:plan => "premium"})
    response.code.should == "200"

    data = JSON.parse(response.body)
    data["stripe"].should be_a_kind_of(Hash)
    data["stripe"].should include("status" => "trialing", "cost" => 1500, "plan" => "premium", "change_type" => "upgrade")
    data["stripe"]["period_end"].should_not be_nil

    @user.reload
    @user.total_syncs.should == 0
    @user.next_sync.should be_within(5).of(@user.feature_limit(:sync_hrs).hours.from_now.utc)

    @user.subscription.should be_a_kind_of(Subscription)
    @user.subscription.status.should == "trialing"
    @user.subscription.plan.should == "premium"
    @user.subscription.trial_end.to_time.to_i.should be_within(4.days).of(30.days.from_now.to_i)

    @user.stripe_id.should_not be_nil
    @user.stripe_card.should be_a_kind_of(Hash)
    @user.stripe_card.should == {"last4" => "4242", "type" => "Visa", "exp_year" => Date.today.year + 1, "exp_month" => 1}

    website.reload
    website.domain_paid.should be_true
    website.seo_paid.should be_true
    website.brand_paid.should be_true
  end

  it "downgrades an existing subscription" do
    website = create(:website, :user => @user, :domain_paid => true, :seo_paid => true)

    EphemeralResponse.fixture_set = :billing_downgrade
    customer = Stripe::Customer.create(:card => {:number => "4242424242424242", :exp_month => 1, :exp_year => Date.today.year + 1, :cvc => 534}, :plan => "starter")

    @user.build_subscription(:plan => "premium")
    @user.total_syncs = 2
    @user.next_sync = 1.hour.from_now.utc
    @user.stripe_card = {"last4" => customer.active_card.last4, "type" => customer.active_card.type, "exp_year" => customer.active_card.exp_year, "exp_month" => customer.active_card.exp_month}
    @user.stripe_id = customer.id
    @user.save

    post(:purchase, {:plan => "starter"})
    response.code.should == "200"

    data = JSON.parse(response.body)
    data["stripe"].should be_a_kind_of(Hash)
    data["stripe"].should include("status" => "trialing", "cost" => 500, "plan" => "starter", "change_type" => "downgrade")
    data["stripe"]["period_end"].should_not be_nil

    @user.reload
    @user.total_syncs.should == 2
    @user.next_sync.should be_within(2).of(1.hour.from_now.utc)

    @user.subscription.should be_a_kind_of(Subscription)
    @user.subscription.status.should == "trialing"
    @user.subscription.plan.should == "starter"
    @user.subscription.trial_end.to_time.to_i.should be_within(4.days).of(30.days.from_now.to_i)

    @user.stripe_id.should_not be_nil
    @user.stripe_card.should be_a_kind_of(Hash)
    @user.stripe_card.should == {"last4" => "4242", "type" => "Visa", "exp_year" => Date.today.year + 1, "exp_month" => 1}

    website.reload
    website.domain_paid.should be_true
    website.seo_paid.should_not be_true
    website.brand_paid.should_not be_true
  end

  it "errors on bad coupon" do
    @user.save
    EphemeralResponse.fixture_set = :billing_bad_coupon

    creditcard = Stripe::Token.create(:card => {:number => "4242424242424242", :exp_month => 1, :exp_year => Date.today.year + 1, :cvc => 534})

    post(:purchase, {:plan => "starter", :token => creditcard.id, :coupon => "1234"})
    response.code.should == "400"
    response.body.should == '{"stripe_error":{"message":"No such coupon: 1234","param":"coupon","type":"invalid_request_error"}}'

    @user.reload
    @user.subscription.should be_nil
    @user.stripe_id.should be_nil
    @user.stripe_card.should == {}
  end

  it "updates an existing credit card" do
    EphemeralResponse.fixture_set = :billing_update_existing
    customer = Stripe::Customer.create(:card => {:number => "4242424242424242", :exp_month => 2, :exp_year => Date.today.year + 2, :cvc => 666})
    @user.stripe_card = {"last4" => customer.active_card.last4, "type" => customer.active_card.type, "exp_year" => customer.active_card.exp_year, "exp_month" => customer.active_card.exp_month}
    @user.stripe_id = customer.id
    @user.save

    creditcard = Stripe::Token.create(:card => {:number => "4242424242424242", :exp_month => 1, :exp_year => Date.today.year + 1, :cvc => 534})

    put(:update, {:token => creditcard.id})
    response.code.should == "200"

    @user.reload
    @user.stripe_card.should == {"last4" => "4242", "type" => "Visa", "exp_year" => Date.today.year + 1, "exp_month" => 1}
    @user.stripe_id.should == customer.id
  end

  it "updates with a new creditcard" do
    @user.save
    EphemeralResponse.fixture_set = :billing_update_new

    creditcard = Stripe::Token.create(:card => {:number => "4242424242424242", :exp_month => 1, :exp_year => Date.today.year + 1, :cvc => 534})
    put(:update, {:token => creditcard.id})
    response.code.should == "200"

    @user.reload
    @user.stripe_card.should == {"last4" => "4242", "type" => "Visa", "exp_year" => Date.today.year + 1, "exp_month" => 1}
  end

  it "cancels an existing subscription" do
    @user.save
    website = create(:website, :user => @user, :domain_paid => true, :seo_paid => false)

    EphemeralResponse.fixture_set = :billing_cancel

    Subscription.any_instance.should_not_receive(:strip_features)

    creditcard = Stripe::Token.create(:card => {:number => "4242424242424242", :exp_month => 1, :exp_year => Date.today.year + 1, :cvc => 534})

    post(:purchase, {:plan => "starter", :token => creditcard.id})
    response.code.should == "200"

    @user.reload
    @user.subscription.should be_a_kind_of(Subscription)
    @user.subscription.status.should == "trialing"
    @user.subscription.plan.should == "starter"

    delete(:cancel_subscription)

    @user.reload
    @user.subscription.status.should == "canceled"

    website.reload
    website.domain_paid.should be_true
    website.seo_paid.should_not be_true
    website.brand_paid.should_not be_true
  end
end