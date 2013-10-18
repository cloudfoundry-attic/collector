module Collector
  class Handler
    class MarketplaceGateway < ServiceGatewayHandler
      def service_type
        'marketplace'
      end

      register Components::MARKETPLACE_GATEWAY
    end
  end
end
