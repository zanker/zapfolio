module Resque
  module Failure
    # Bug with Resque failure not cleaning up dirty exit locks
    class Locksmith < Base
      def save
        work = payload["class"]
        if work.respond_to?(:lock)
          Resque.redis.del(work.lock(*payload["args"]))
        end
      end
    end
  end

  module Plugins
    module Lock
      # Lock keys not being the same when relying on serializer
      def lock(*args)
        "lock:#{name}-#{Resque.encode(args)}"
      end

      def on_failure_lock(error, *args)
        Resque.redis.del(lock(*args))
      end
    end
  end
end