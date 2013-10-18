module Collector
  class Handler
    class PostgresqlProvisioner < ServiceGatewayHandler
      def service_type
        "postgresql"
      end

      register Components::PGSQL_PROVISIONER
    end
  end
end
