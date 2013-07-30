require "time"
require "dogapi"
require "collector/config"

module Collector
  class Historian
    class DataDog
      def initialize(api_key, application_key)
        @dog_client = Dogapi::Client.new(api_key, application_key, nil, nil, false)
      end

      def send_data(data)
        name = "cf.collector.#{data[:key].to_s}"
        time = data.fetch(:timestamp, Time.now.to_i)
        point = [Time.at(time), data[:value]]
        tags = data[:tags].flat_map do |key, value|
          Array(value).map do |v|
            "#{key}:#{v}"
          end
        end

        EventMachine.defer do
          begin
            @dog_client.emit_points(name, [point], tags: tags)
          rescue
            Config.logger.warn("collector.emit-datadog.fail", metric_name: "some_metric.some_key")
          end
        end
      end
    end
  end
end
