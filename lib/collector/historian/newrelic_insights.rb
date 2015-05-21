require "time"
require "collector/config"

module Collector
  class Historian
    class NewrelicInsights
      def initialize(api_key, app_id, http_client)
        @api_key = api_key
        @app_id = app_id
        @http_client = http_client

        @metrics = []
        @timestamp_of_last_post = Time.now
      end

      def send_data(data)
        @metrics << formatted_metric_for_data(data)

        time_since_last_post = Time.now - @timestamp_of_last_post
        if @metrics.size >= Config.newrelic_insights_data_threshold || time_since_last_post >= Config.newrelic_insights_time_threshold_in_seconds
          send_metrics(@metrics.dup)

          @metrics.clear
          @timestamp_of_last_post = Time.now
        end
      end

      private

      def formatted_metric_for_data(data)
        {
          eventType: "#{Config.deployment_name.gsub('-', '_')}",
          key: data[:key].split('.')[-1],
          tree: data[:key].rpartition('.').first,
          full_key: data[:key],
          value: data[:value],
          timestamp: data.fetch(:timestamp, Time.now.to_i)
        }.merge(data[:tags])
      end

      def send_metrics(metrics)
        start = Time.now
        EM.defer do
          Config.logger.debug("Sending metrics to newrelic: [#{metrics.inspect}]")
          body = Yajl::Encoder.encode( metrics )
          response = @http_client.post("https://insights-collector.newrelic.com/v1/accounts/#{@app_id}/events",
            body: body, 
            headers: {
              "Content-type" => "application/json",
              "X-Insert-Key" => @api_key
            }
          )
          if response.success?
            Config.logger.info("collector.emit-newrelic-insights.success", number_of_metrics: metrics.count, lag_in_seconds: Time.now - start)
          else
            Config.logger.warn("collector.emit-newrelic-insights.fail", number_of_metrics: metrics.count, lag_in_seconds: Time.now - start)
          end
        end
      end
    end
  end
end
