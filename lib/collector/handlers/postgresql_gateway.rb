# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class PostgresqlProvisioner < ServiceGatewayHandler
      def initialize(*args)
        PostgresqlProvisioner.register Components::PGSQL_PROVISIONER
        super
      end

      def service_type
        "postgresql"
      end

    end
  end
end
