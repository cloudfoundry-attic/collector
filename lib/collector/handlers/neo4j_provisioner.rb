# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class Neo4jProvisioner < ServiceGatewayHandler
      def initialize(*args)
        Neo4jProvisioner.register Components::NEO4J_PROVISIONER
        super
      end

      def service_type
        "neo4j"
      end

    end
  end
end
