# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class Router < Handler
      def process(context)
        varz = context.varz

        send_metric("router.total_requests", varz["requests"], context)
        send_metric("router.total_routes", varz["urls"], context)
        send_metric("router.ms_since_last_registry_update", varz["ms_since_last_registry_update"], context)

        return unless varz["tags"]
        varz["tags"].each do |key, values|
          values.each do |value, metrics|
            if key == "component" && value.start_with?("dea-")
              # dea_id looks like "dea-1", "dea-2", etc
              dea_id = value.split("-")[1]

              # These are app requests, not requests to the dea. So we change the component to "app".
              tags = {:component => "app", :dea_index => dea_id }
            else
              tags = {key => value}
            end

            send_metric("router.requests", metrics["requests"], context, tags)
            send_latency_metric("router.latency.1m", metrics["latency"], context, tags)
            ["2xx", "3xx", "4xx", "5xx", "xxx"].each do |status_code|
              send_metric("router.responses", metrics["responses_#{status_code}"], context, tags.merge("status" => status_code))
            end
          end
        end
      end

      register Components::ROUTER_COMPONENT
    end
  end
end
