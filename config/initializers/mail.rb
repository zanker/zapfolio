if Rails.env.production? or Rails.env.worker?
  auth = {:user_name => CONFIG[:sendgrid][:username], :password => CONFIG[:sendgrid][:password], :domain => "zapfol.io", :address => "smtp.sendgrid.net", :port => 587, :authentication => :plain, :enable_starttls_auto => true}

  ActionMailer::Base.add_delivery_method :smtp, Mail::SMTP, auth
  ActionMailer::Base.delivery_method = :smtp

  Mail.defaults do
    delivery_method :smtp, auth
  end
else
  ActionMailer::Base.delivery_method = :test

  Mail.defaults do
    delivery_method :test
  end
end