module Collector
  class Handler
    class MarketplaceGateway < ServiceGatewayHandler
      def service_type
        'marketplace'
      end

      def additional_tags(context)
        { ip: context.varz["host"].split(":").first }
      end

      register Components::MARKETPLACE_GATEWAY
    end
  end
end
