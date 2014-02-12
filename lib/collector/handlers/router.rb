module Collector
  class Handler
    class Router < Handler
      def additional_tags(context)
        { ip: context.varz["host"].split(":").first,
        }
      end

      def process(context)
        varz = context.varz

        send_metric("router.total_requests", varz["requests"], context)
        send_metric("router.received_requests", varz["received_requests"], context)
        send_metric("router.total_routes", varz["urls"], context)
        send_metric("router.ms_since_last_registry_update", varz["ms_since_last_registry_update"], context)

        send_metric("router.bad_requests", varz["bad_requests"], context)
        send_metric("router.bad_gateways", varz["bad_gateways"], context)

        return unless varz["tags"]

        app_requests = 0
        varz["tags"].each do |key, values|
          values.each do |value, metrics|
            if key == "component" && value.start_with?("dea-")
              # dea_id looks like "dea-1", "dea-2", etc
              dea_id = value.split("-")[1]

              # These are app requests, not requests to the dea. So we change the component to "app".
              tags = {:component => "app", :dea_index => dea_id }
              app_requests += metrics["requests"]
            else
              tags = {key => value}
            end

            send_metric("router.requests", metrics["requests"], context, tags)
            send_latency_metric("router.latency.1m", metrics["latency"], context, tags)
            ["2xx", "3xx", "4xx", "5xx", "xxx"].each do |status_code|
              component_responses_by_status_code = metrics["responses_#{status_code}"]
              send_metric("router.responses", component_responses_by_status_code, context, tags.merge("status" => status_code))
            end
          end
        end
        send_metric("router.routed_app_requests", app_requests, context)
      end

      register Components::ROUTER_COMPONENT
    end
  end
end
