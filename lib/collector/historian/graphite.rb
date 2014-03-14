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

      def create_metrics_name(p)
        # Given a properties hash like so
        # {:key=>"cpu_load_avg", :timestamp=>1394801347, :value=>0.25, :tags=>{:ip=>"172.30.5.74", :role=>"core", :job=>"CloudController", :index=>0, :name=>"CloudController/0", :deployment=>"CF"}}
        # One will get a metrics key like so
        # CF.CloudController0.cpu_load_avg

        [p[:tags][:deployment], p[:tags][:name].gsub('/',''), p[:key]].join '.'
      end

      def validate_value(value)
        if value.is_a? Integer or value.is_a? Float
          return value
        end
        Config.logger.error("collector.emit-graphite.fail: Value is not a float or int, got: #{value}")
        nil
      end

      def validate_timestamp(ts)
        # If we are missing a timestamp return now
        if not ts
          return Time.now.to_i
        end
        # If the timestamp is not unix epoch format return now
        if not /^1[0-9]{9}$/.match(ts.to_s)
          return Time.now.to_i
        end
        ts
      end



      def send_data(properties)
        metrics_name = create_metrics_name(properties)
        value = validate_value(properties[:value])
        timestamp = validate_timestamp(properties[:timestamp])

        if metrics_name and value and timestamp
          puts
          command =  "#{metrics_name} #{value} #{timestamp}"
          @connection.send_data(command)
        end
      end
    end
  end
end
