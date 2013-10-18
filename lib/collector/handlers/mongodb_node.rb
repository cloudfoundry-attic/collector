module Collector
  class Handler
    class MongodbNode < ServiceNodeHandler
      def service_type
        "mongodb"
      end
      register Components::MONGODB_NODE
    end
  end
end
