require "spec_helper"

describe Usercp::UsersController do
  it "unflags an user" do
    user = create(:flickr_user, :flags => {:test => true})
    request.session[:user_id] = user._id
    request.cookie_jar.signed[:remember_token] = user.remember_token

    put(:unflag, {:flag => "test"})
    response.code.should == "204"

    user.reload
    user.flags.should == {}
  end

  it "updates settings" do
    user = create(:flickr_user, :flags => {:test => true})
    request.session[:user_id] = user._id
    request.cookie_jar.signed[:remember_token] = user.remember_token

    put(:update, {:email => "foobar@zapfol.io", :full_name => "Foo Bar", :receive_emails => "0"})
    response.code.should == "200"

    user.reload
    user.email.should == "foobar@zapfol.io"
    user.full_name.should == "Foo Bar"
    user.receive_emails.should_not be_true
  end

  it "unsubscribes using a valid email token" do
    user = create(:flickr_user, :receive_emails => true)
    request.session[:user_id] = user._id
    request.cookie_jar.signed[:remember_token] = user.remember_token

    get(:unsubscribe, {:user_id => user._id.to_s, :email_token => user.email_token})
    response.code.should == "302"
    response.should redirect_to(edit_users_path)

    user.reload
    user.receive_emails.should be_false
  end

  it "does not unsubscribe with an invalid email token" do
    user = create(:flickr_user, :receive_emails => true)
    request.session[:user_id] = user._id
    request.cookie_jar.signed[:remember_token] = user.remember_token

    get(:unsubscribe, {:user_id => user._id.to_s, :email_token => "TEST TEST"})
    response.code.should == "302"
    response.should redirect_to(websites_path)

    user.reload
    user.receive_emails.should be_true
  end

  context "returns job statuses for the album job" do
    before :each do
      @user = create(:flickr_user, :flags => {:test => true}, :jobs => {"album" => "1234"})
      request.session[:user_id] = @user._id
      request.cookie_jar.signed[:remember_token] = @user.remember_token
    end

    it "and queues without when not over limit" do
      User.any_instance.should_receive(:syncing).and_return(false)
      User.any_instance.should_receive(:can_resync?).and_return(true)

      Resque::Plugins::Status::Hash.should_receive(:get).with("1111").and_return({"status" => "queued"})
      Job::Flickr::Album.should_receive(:create_to).with(:low, :user_id => @user._id).and_return("1111")

      post(:job_status, {:queue => "1"})
      response.body.should == '{"loading":true,"status":"queued_albums"}'

      @user.reload
      @user.total_syncs.should == 1
      @user.jobs.should == {"album" => "1111"}
    end

    it "and does not queue when over the limit" do
      User.any_instance.should_receive(:syncing).twice.and_return(false)
      User.any_instance.should_receive(:can_resync?).and_return(false)
      Job::Flickr::Album.should_not_receive(:create_to)

      post(:job_status, {:queue => "1"})

      body = JSON.parse(response.body)
      body["albums"].should == []
      body["user"].should include("id" => @user._id.to_s)
    end

    it "on failure" do
      Resque::Plugins::Status::Hash.should_receive(:get).with("1234").and_return({"status" => "failed"})
      User.any_instance.should_receive(:unset).with(:"jobs.album").once

      post(:job_status)
      response.body.should == '{"loading":true,"status":"error"}'
    end

    it "on completion" do
      Resque::Plugins::Status::Hash.should_receive(:get).with("1234").and_return({"status" => "completed"})
      Resque::Plugins::Status::Hash.should_receive(:get).with(nil).and_return(nil)
      User.any_instance.should_receive(:unset).with(:"jobs.album").once { @user.jobs.delete("album") }

      post(:job_status)

      body = JSON.parse(response.body)
      body["albums"].should == []
      body["user"].should include("id" => @user._id.to_s)
    end

    it "on running" do
      Resque::Plugins::Status::Hash.should_receive(:get).with("1234").and_return({"status" => "working", "album" => "Foo Bar"})

      post(:job_status)
      response.body.should == '{"loading":true,"status":"albums","album":"Foo Bar"}'
    end

    it "on queued" do
      Resque::Plugins::Status::Hash.should_receive(:get).with("1234").and_return({"status" => "queued"})

      post(:job_status)
      response.body.should == '{"loading":true,"status":"queued_albums"}'
    end

    it "on nil status" do
      Resque::Plugins::Status::Hash.should_receive(:get).with("1234").and_return(nil)
      User.any_instance.should_receive(:unset).with(:"jobs.album").once { @user.jobs.delete("album") }

      post(:job_status)

      body = JSON.parse(response.body)
      body["albums"].should == []
      body["user"].should include("id" => @user._id.to_s)
    end
  end

  context "returns job statuses for the media job" do
    before :each do
      @user = create(:flickr_user, :flags => {:test => true}, :jobs => {"media" => "4321"})
      request.session[:user_id] = @user._id
      request.cookie_jar.signed[:remember_token] = @user.remember_token
    end

    it "on failure" do
      Resque::Plugins::Status::Hash.should_receive(:get).with("4321").and_return({"status" => "failed"})
      User.any_instance.should_receive(:unset).with(:"jobs.album").once { @user.jobs.delete("album") }
      User.any_instance.should_receive(:unset).with(:"jobs.media").once { @user.jobs.delete("media") }

      post(:job_status)
      response.body.should == '{"loading":true,"status":"error"}'
    end

    it "on completion" do
      Resque::Plugins::Status::Hash.should_receive(:get).with("4321").and_return({"status" => "completed"})
      User.any_instance.should_receive(:unset).with(:"jobs.album").once { @user.jobs.delete("album") }
      User.any_instance.should_receive(:unset).with(:"jobs.media").once { @user.jobs.delete("media") }

      post(:job_status)

      body = JSON.parse(response.body)
      body["albums"].should == []
      body["user"].should include("id" => @user._id.to_s)
    end

    it "on running" do
      Resque::Plugins::Status::Hash.should_receive(:get).with("4321").and_return({"status" => "working", "area" => "photos", "num" => 1, "total" => 10})

      post(:job_status)
      response.body.should == '{"loading":true,"status":"photos","total":10,"loaded":1,"progress":0.1}'
    end

    it "on queued" do
      Resque::Plugins::Status::Hash.should_receive(:get).with("4321").and_return({"status" => "queued"})

      post(:job_status)
      response.body.should == '{"loading":true,"status":"queued_media"}'
    end

    it "on nil status" do
      Resque::Plugins::Status::Hash.should_receive(:get).with("4321").and_return(nil)
      User.any_instance.should_receive(:unset).with(:"jobs.media").once { @user.jobs.delete("media") }

      post(:job_status)

      body = JSON.parse(response.body)
      body["albums"].should == []
      body["user"].should include("id" => @user._id.to_s)
    end
  end
end