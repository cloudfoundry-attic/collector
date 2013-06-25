# Copyright (c) 2009-2012 VMware, Inc.

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
