require "time"
require "collector/config"

module Collector
  class Historian
    class DataDog
      DATA_THRESHOLD = 100
      TIME_THRESHOLD_IN_SECONDS = 10

      def initialize(api_key, http_client)
        @api_key = api_key
        @http_client = http_client

        @metrics = []
        @timestamp_of_last_post = Time.now
      end

      def send_data(data)
        @metrics << formatted_metric_for_data(data)

        time_since_last_post = Time.now - @timestamp_of_last_post
        if @metrics.size >= DATA_THRESHOLD || time_since_last_post >= TIME_THRESHOLD_IN_SECONDS
          send_metrics(@metrics.dup)

          @metrics.clear
          @timestamp_of_last_send = Time.now
        end
      end

      private

      def metric_for_data(data)
        "cf.collector.#{data[:key].to_s}"
      end

      def formatted_metric_for_data(data)
        metric = metric_for_data(data)
        points = [[data.fetch(:timestamp, Time.now.to_i), data[:value]]]
        tags = data[:tags].flat_map do |key, value|
          Array(value).map do |v|
            "#{key}:#{v}"
          end
        end

        {
          metric: metric,
          points: points,
          type: "gauge",
          tags: tags
        }
      end

      def send_metrics(metrics)
        EM.defer do
          body = Yajl::Encoder.encode({ series: metrics })
          response = @http_client.post("https://app.datadoghq.com/api/v1/series", query: {api_key: @api_key}, body: body, headers: {"Content-type" => "application/json"})
          if response.success?
            Config.logger.info("collector.emit-datadog.success", number_of_metrics: metrics.count)
          else
            Config.logger.warn("collector.emit-datadog.fail", number_of_metrics: metrics.count)
          end
        end
      end
    end
  end
end
