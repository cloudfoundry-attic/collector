# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class MongodbProvisioner < ServiceGatewayHandler
      def initialize(*args)
        MongodbProvisioner.register Components::MONGODB_PROVISIONER
        super
      end

      def service_type
        "mongodb"
      end

    end
  end
end
