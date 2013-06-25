# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class RedisNode < ServiceNodeHandler
      def initialize(*args)
        RedisNode.register Components::REDIS_NODE
        super
      end

      def service_type
        "redis"
      end
    end
  end
end
