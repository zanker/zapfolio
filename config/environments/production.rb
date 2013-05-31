Zapfolio::Application.configure do
  Haml::Template.options[:ugly] = true

  config.action_controller.page_cache_directory = "public/cache"

  config.action_controller.asset_host = "//d14xsgzu2tdv9s.cloudfront.net"

  config.middleware.use Rack::SslEnforcer, :hsts => {:subdomains => false}

  # Passenger has a bug where when using "listen 443 default ssl" (or anything besides "ssl on"), it won't set the HTTPS env. We have to check for port to fix that.
  # http://code.google.com/p/phusion-passenger/issues/detail?id=401&colspec=ID%20Type%20Status%20Priority%20Milestone%20Stars%20Summary
  module ActionDispatch
    module Http
      module URL
        def ssl?
          @env['HTTPS'] == 'on' || @env['HTTP_X_FORWARDED_PROTO'] == 'https' || @env['SERVER_PORT'].to_i == 443
        end
      end
    end
  end

  module Rack
    class SslEnforcer
      private
      alias_method :scheme_old, :scheme
      def scheme(env)
        ( env['SERVER_PORT'].to_i == 443 ? "https" : scheme_old(env) )
      end
    end
  end

  config.assets.compress = true
  config.assets.compile = false
  config.assets.digest = true
  config.assets.js_compressor = :uglifier
  config.assets.css_compressor = :less

  config.cache_classes = true

  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  config.serve_static_assets = false

  config.i18n.fallbacks = true

  config.active_support.deprecation = :notify
end
