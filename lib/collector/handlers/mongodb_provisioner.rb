module Collector
  class Handler
    class MongodbProvisioner < ServiceGatewayHandler
      def service_type
        "mongodb"
      end

      register Components::MONGODB_PROVISIONER
    end
  end
end
