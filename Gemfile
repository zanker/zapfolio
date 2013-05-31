source "https://code.stripe.com"
source "https://rubygems.org"

gem "rails", "~>3.2.8"

gem "json", "~>1.7"

gem "dragonfly", "~>0.9.12"

gem "fog"

gem "airbrake"

gem "stripe", "~>1.7.0"

gem "bcrypt-ruby", "~>3.0.1"

gem "mongo_mapper", "~>0.11.1"
gem "mongo", "~>1.6.4"
gem "bson_ext", "~>1.6.4"

gem "omniauth", "~>1.1.0"
gem "omniauth-flickr", "~>0.0.9"
gem "omniauth-smugmug", "~>1.0.0", :git => "git@github.com:Zapfolio/omniauth-smugmug.git"

gem "sanitize", "~>2.0.3"

gem "resque", "~>1.20.0"
gem "resque-scheduler", "~>2.0.0.h"
gem "resque_mailer", "~>2.0.3"
gem "resque-retry", "~>1.0.0.a"
gem "resque-lock", "~>1.0.0"
gem "resque-status", "0.3.2"

gem "haml", "~>3.2.0.beta.3"

gem "i18n-js", "~>2.1.2"

group :worker do
  gem "flickraw-cached"
  gem "ruby-smugmug", :git => "git@github.com:zanker/ruby-smugmug.git"
end

group :production do
  gem "rack-ssl-enforcer", :require => "rack/ssl-enforcer"
end

group :blog do
  gem "rdiscount"
end

group :assets do
  gem "sprockets"

  gem "less-rails"
  gem "less"

  gem "sass-rails"
  gem "sass"

  gem "compass"
  gem "compass-rails"
  gem "oily_png"

  gem "jquery-rails"
  gem "rails-backbone"
  gem "handlebars_assets"
  gem "haml_assets"

  gem "therubyracer", :platform => :ruby
  gem "uglifier", ">= 1.0.3"
end

group :development do
  gem "thin"

  gem "capistrano"
  gem "capistrano_colors"

  gem "rails-dev-tweaks"
end

group :development, :test do
  gem "request_profiler"
end

group :test do
  gem "capybara"
  gem "ephemeral_response"

  gem "rspec"
  gem "rspec-rails"

  gem "guard"
  gem "guard-rspec"

  gem "factory_girl"
  gem "factory_girl_rails"

  gem "timecop"
end
