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
