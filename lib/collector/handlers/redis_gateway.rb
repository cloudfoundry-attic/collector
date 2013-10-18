module Collector
  class Handler
    class RedisProvisioner < ServiceGatewayHandler
      def service_type
        "redis"
      end
      register Components::REDIS_PROVISIONER
    end
  end
end
