# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class Neo4jNode < ServiceNodeHandler
      def initialize(*args)
        Neo4jNode.register Components::NEO4J_NODE
        super
      end

      def service_type
        "neo4j"
      end
    end
  end
end
