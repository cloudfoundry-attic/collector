module Collector
  class Handler
    class RabbitmqNode < ServiceNodeHandler
      def service_type
        "rabbitmq"
      end

      register Components::RABBITMQ_NODE
    end
  end
end
