require File.expand_path("../boot", __FILE__)

require "action_controller/railtie"
require "action_mailer/railtie"
require "active_resource/railtie"
require "sprockets/railtie"

if defined?(Bundler)
  Bundler.require(*Rails.groups(:assets => ["development", "test"]))
end

module Zapfolio
  class Application < Rails::Application
    Dir[Rails.root.join("shared/mongo_mapper/**/*.rb")].each {|f| require f}

    config.autoload_paths += [Rails.root.join("lib"), Rails.root.join("shared", "models")]

    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.yml")]

    config.filter_parameters += [:password, :password_confirmation]

    config.assets.logger = false

    config.assets.enabled = true
    config.assets.precompile << "usercp.js"
    config.assets.precompile << "usercp.css"

    config.exceptions_app = self.routes

    if config.respond_to?(:less)
      config.less.paths << Rails.root.join("app", "assets", "stylesheets", "bootstrap")
    end

    if defined?(Compass)
      Compass.configuration.generated_images_path = "#{config.root}/public/assets/"
      Compass.configuration.generated_images_dir = "public/assets/"
    end

    Haml::Template.options[:format] = :html5

    config.encoding = "utf-8"

    config.after_initialize do
      ActionMailer::Base.default_url_options[:host] = CONFIG[:domain]
    end

    config.middleware.insert(0, "Dragonfly::Middleware", :images)
  end
end
