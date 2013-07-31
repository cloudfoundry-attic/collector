require "time"
require "collector/config"
require "httparty"

module Collector
  class Historian
    class DataDog
      def initialize(api_key)
        @api_key = api_key
      end

      def send_data(data)
        body = post_body_for_data(data)

        EM.defer do
          response = HTTParty.post("https://app.datadoghq.com/api/v1/series", query: {api_key: @api_key}, body: body, headers: {"Content-type" => "application/json"})
          unless response.success?
            Config.logger.warn("collector.emit-datadog.fail", metric_name: metric_for_data(data))
          end
        end
      end

      private

      def metric_for_data(data)
        "cf.collector.#{data[:key].to_s}"
      end

      def post_body_for_data(data)
        metric = metric_for_data(data)
        time = data.fetch(:timestamp, Time.now.to_i)
        points = [[time, data[:value]]]
        tags = data[:tags].flat_map do |key, value|
          Array(value).map do |v|
            "#{key}:#{v}"
          end
        end

        Yajl::Encoder.encode({
                               series: [
                                 {
                                   metric: metric,
                                   points: points,
                                   type: "gauge",
                                   tags: tags
                                 }
                               ]
                             })
      end
    end
  end
end
