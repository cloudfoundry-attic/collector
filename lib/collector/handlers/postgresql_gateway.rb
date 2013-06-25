# Copyright (c) 2009-2012 VMware, Inc.

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
