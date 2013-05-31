Airbrake.configure do |config|
  config.secure = false
  config.api_key = "<KEY>"
  config.environment_name = "production" if Rails.env.worker?

  Zapfolio::Application.config.filter_parameters.each {|p| config.params_filters << p}
end