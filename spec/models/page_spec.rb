require "spec_helper"

describe Page do
  it "encrypts a password" do
    page = build(:page, :website => create(:website))
    page.password = "foobar"
    page.password_confirmation = "foobar"
    page.save

    page.password.should be_nil
    page.password_confirmation.should be_nil

    password = BCrypt::Password.new(page.encrypted_password)
    password.should == "foobar"
  end
end