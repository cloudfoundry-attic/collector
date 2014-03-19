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

      def get_metrics_name(p)
        # Given a properties hash like so
        # {:key=>"cpu_load_avg", :timestamp=>1394801347, :value=>0.25, :tags=>{:ip=>"172.30.5.74", :role=>"core", :job=>"CloudController", :index=>0, :name=>"CloudController/0", :deployment=>"CF"}}
        # One will get a metrics key like so
        # CF.CloudController0.cpu_load_avg
        deployment = p[:tags][:deployment]
        job = p[:tags][:job]
        index = p[:tags][:index]
        key = p[:key]
        if deployment && job && index && key
          return [deployment, job, index, key].join '.'
        end
        Config.logger.error("collector.create-graphite-key.fail: Could not create metrics name from fields tags.deployment, tags.job, tags.index or key.")
      end

      def get_value(value)
        if value.is_a? Integer or value.is_a? Float
          return value
        end
        Config.logger.error("collector.emit-graphite.fail: Value is not a float or int, got: #{value}")
      end

      def get_timestamp(ts)
        # If we are missing a timestamp return now
        unless ts
          return Time.now.to_i
        end
        # If the timestamp is not unix epoch format return now
        if not /^1[0-9]{9}$/.match(ts.to_s)
          return Time.now.to_i
        end
        ts
      end

      def send_data(properties)
        metrics_name = get_metrics_name(properties)
        value = get_value(properties[:value])
        timestamp = get_timestamp(properties[:timestamp])
        if metrics_name && value && timestamp
          @connection.send_data("#{metrics_name} #{value} #{timestamp}\n")
        end
      end
    end
  end
end
