# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class VblobNode < ServiceNodeHandler
      def initialize(*args)
        VblobNode.register Components::VBLOB_NODE
        super
      end

      def service_type
        "vblob"
      end
    end
  end
end
