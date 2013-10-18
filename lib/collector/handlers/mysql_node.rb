module Collector
  class Handler
    class MysqlNode < ServiceNodeHandler
      def service_type
        "mysql"
      end

      register Components::MYSQL_NODE
    end
  end
end
