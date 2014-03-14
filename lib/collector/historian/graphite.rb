require 'collector/graphite_connection'

module Collector
  class Historian
    class Graphite
      attr_reader :connection
      def initialize(host, port)
        @host = host
        @port = port
        @connection = EventMachine.connect(@host, @port, GraphiteConnection)
      end

      def validate_timestamp(properties)
        # If we are missing a timestamp return now
        if not properties.has_key? :timestamp
          return Time.now.to_i
        end
        # If the timestamp is not unix epoch format return now
        if not /^1[0-9]{9}$/.match(properties[:timestamp].to_s)
          return Time.now.to_i
        end
        properties[:timestamp]
      end

      def send_data(properties)
        tags = (properties[:tags].flat_map do |key, value|
          Array(value).map do |v|
            "#{key}=#{v}"
          end
        end).sort.join(" ")

        timestamp = validate_timestamp(properties)

        command = "#{properties[:key]} #{properties[:value]} #{timestamp}"
        @connection.send_data(command)
      end
    end
  end
end
