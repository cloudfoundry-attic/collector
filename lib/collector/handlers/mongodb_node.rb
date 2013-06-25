# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class MongodbNode < ServiceNodeHandler
      def initialize(*args)
        MongodbNode.register Components::MONGODB_NODE
        super
      end

      def service_type
        "mongodb"
      end
    end
  end
end
