require "resque/failure/multiple_with_retry_suppression"
require "resque/failure/redis"
require "resque/failure/airbrake"

Resque.redis = YAML.load_file(Rails.root.join("config/redis.yml"))[Rails.env]
Resque::Plugins::Status::Hash.expire_in = 1.hour

Resque::Failure::MultipleWithRetrySuppression.classes = [Resque::Failure::Redis, Resque::Failure::Airbrake, Resque::Failure::Locksmith]
Resque::Failure.backend = Resque::Failure::MultipleWithRetrySuppression