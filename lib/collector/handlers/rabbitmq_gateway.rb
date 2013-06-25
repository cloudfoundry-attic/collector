# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class RabbitmqProvisioner < ServiceGatewayHandler

      def service_type
        "rabbitmq"
      end
      register Components::RABBITMQ_PROVISIONER
    end
  end
end
