# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class RabbitmqNode < ServiceNodeHandler
      def initialize(*args)
        RabbitmqNode.register Components::RABBITMQ_NODE
        super
      end

      def service_type
        "rabbitmq"
      end
    end
  end
end
