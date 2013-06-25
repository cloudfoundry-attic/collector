# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class PostgresqlNode < ServiceNodeHandler
      def service_type
        "postgresql"
      end

      register Components::PGSQL_NODE
    end
  end
end
