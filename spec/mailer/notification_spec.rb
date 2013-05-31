require "spec_helper"

describe Notification do
  include MongoMocker::Finders

  before :all do
    @user = build(:flickr_user, :stripe_card => {"type" => "Visa", "last4" => "1324", "exp_month" => 3, "exp_year" => 2012})
    @user.build_subscription(:plan => "starter", :trial_end => 5.days.from_now.utc, :period_end => 5.days.from_now.utc)
  end

  it "sends a trial will end email" do
    mock_where_finder(@user)

    Notification.trial_will_end(@user._id.to_s).deliver!
    ActionMailer::Base.deliveries.should have(1).email
  end

  it "sends a payment received email" do
    mock_where_finder(@user)

    Notification.invoice_payment_succeeded(@user._id.to_s, {"total" => 1533.55}).deliver!
    ActionMailer::Base.deliveries.should have(1).email
  end

  it "sends a payment failed email" do
    mock_where_finder(@user)

    Notification.invoice_payment_failed(@user._id.to_s, {"total" => 1533.55}).deliver!
    ActionMailer::Base.deliveries.should have(1).email
  end
end