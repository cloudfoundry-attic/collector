# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class VblobProvisioner < ServiceGatewayHandler
      def initialize(*args)
        VblobProvisioner.register Components::VBLOB_PROVISIONER
        super
      end

      def service_type
        "vblob"
      end
    end
  end
end
