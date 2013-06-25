# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class MysqlNode < ServiceNodeHandler
      def initialize(*args)
        MysqlNode.register Components::MYSQL_NODE
        super
      end

      def service_type
        "mysql"
      end
    end
  end
end
