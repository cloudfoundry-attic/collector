# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class MysqlProvisioner < ServiceGatewayHandler
      def initialize(*args)
        MysqlProvisioner.register Components::MYSQL_PROVISIONER
        super
      end

      def service_type
        "mysql"
      end

    end
  end
end
