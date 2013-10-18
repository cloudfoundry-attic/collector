module Collector
  class Handler
    class MysqlProvisioner < ServiceGatewayHandler
      def service_type
        "mysql"
      end

      register Components::MYSQL_PROVISIONER
    end
  end
end
