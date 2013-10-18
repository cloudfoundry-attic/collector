module Collector
  class Handler
    class VblobProvisioner < ServiceGatewayHandler
      def service_type
        "vblob"
      end

      register Components::VBLOB_PROVISIONER
    end
  end
end
