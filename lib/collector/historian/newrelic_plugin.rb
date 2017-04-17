require "time"
require "collector/config"

module Collector
  class Historian
    class NewrelicPlugin
      def initialize(license_key, http_client)
        @license_key = license_key
        @http_client = http_client

        @metrics = []
        @timestamp_of_last_post = Time.now
      end

      def send_data(data)
        @metrics << formatted_metric_for_data(data)

        time_since_last_post = Time.now - @timestamp_of_last_post
        if @metrics.size >= Config.newrelic_plugin_data_threshold || time_since_last_post >= Config.newrelic_plugin_time_threshold_in_seconds
          send_metrics(@metrics.dup)

          @metrics.clear
          @timestamp_of_last_post = Time.now
        end
      end

      private

      def metric_for_data(data)
        "Component/#{data[:key].to_s}".gsub('.', '/')
      end

      def formatted_metric_for_data(data)
        metric = metric_for_data(data)

        [metric, data[:value]]
      end

      def send_metrics(metrics)
        start = Time.now
        EM.defer do
          Config.logger.debug("Sending metrics to newrelic: [#{metrics.inspect}]")
          body = Yajl::Encoder.encode({
                    agent: {
                      host: Config.deployment_name,
                      version: "1"
                    },
                    components: [
                      {
                        name: Config.deployment_name,
                        guid: Config.deployment_name,
                        duration: 20,
                        metrics: Hash[*metrics.flatten]
                      }
                    ]
                 })

          response = @http_client.post("https://platform-api.newrelic.com/platform/v1/metrics",
            body: body, 
            headers: {
              "Content-type" => "application/json",
              "X-License-Key" => @license_key
            }
          )
          if response.success?
            Config.logger.info("collector.emit-newrelic-plugin.success", number_of_metrics: metrics.count, lag_in_seconds: Time.now - start)
          else
            Config.logger.warn("collector.emit-newrelic-plugin.fail", number_of_metrics: metrics.count, lag_in_seconds: Time.now - start)
          end
        end
      end
    end
  end
end
