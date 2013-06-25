# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class RabbitmqProvisioner < ServiceGatewayHandler
      def initialize(*args)
        RabbitmqProvisioner.register Components::RABBITMQ_PROVISIONER
        super
      end

      def service_type
        "rabbitmq"
      end
    end
  end
end
