Rails.application.config.middleware.use OmniAuth::Builder do
  configure do |config|
    config.path_prefix = "/sessions"
    config.full_host = CONFIG[:full_domain]
  end

  provider :developer unless Rails.env.production?
  provider :flickr, CONFIG[:oauth][:flickr][:key], CONFIG[:oauth][:flickr][:secret], :scope => "read"
  provider :smugmug, CONFIG[:oauth][:smugmug][:key], CONFIG[:oauth][:smugmug][:secret], :access => "Full"
end
