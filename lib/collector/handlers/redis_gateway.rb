# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class RedisProvisioner < ServiceGatewayHandler
      def initialize(*args)
        RedisProvisioner.register Components::REDIS_PROVISIONER
        super
      end

      def service_type
        "redis"
      end
    end
  end
end
