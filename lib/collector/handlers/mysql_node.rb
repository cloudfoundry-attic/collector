# Copyright (c) 2009-2012 VMware, Inc.

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
