# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class Neo4jNode < ServiceNodeHandler
      def service_type
        "neo4j"
      end

      register Components::NEO4J_NODE
    end
  end
end
