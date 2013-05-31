EphemeralResponse.configure do |config|
  config.expiration = 3.days

  config.register("api.stripe.com") do |request|
    Digest::SHA1.hexdigest("#{request.method}#{request.path}#{request.body.to_s.gsub(/trial_end=([0-9]+)/, "")}")
  end
end