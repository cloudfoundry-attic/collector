# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class PostgresqlNode < ServiceNodeHandler
      def initialize(*args)
        PostgresqlNode.register Components::PGSQL_NODE
        super
      end

      def service_type
        "postgresql"
      end
    end
  end
end
