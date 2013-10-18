module Collector
  class Handler
    class RedisNode < ServiceNodeHandler
      def service_type
        "redis"
      end
      register Components::REDIS_NODE
    end
  end
end
