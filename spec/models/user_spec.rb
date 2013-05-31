require "spec_helper"

describe User do
  it "returns the display name" do
    user = build(:user)
    user.full_name = "full name"
    user.username = "username"

    user.display_name.should == "full name"

    user.full_name = nil

    user.display_name.should == "username"
  end

  it "returns if the user has a feature" do
    user = build(:user)
    user.has_feature?(:static).should be_true
    user.has_feature?(:domain).should be_false

    user.subscription = build(:subscription)

    user.has_feature?(:static).should be_true
    user.has_feature?(:domain).should be_true
  end

  it "returns the feature limit" do
    user = build(:user)
    user.feature_limit(:media).should == CONFIG[:subscriptions][:free][:features][:media]

    user.subscription = build(:subscription)

    user.feature_limit(:media).should == CONFIG[:subscriptions][:premium][:features][:media]
  end
end