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

      def send_data(properties)
        metrics_name = get_metrics_name(properties)
        value = get_value(properties[:value])
        timestamp = get_timestamp(properties[:timestamp])

        if metrics_name && value && timestamp
          @connection.send_data("#{metrics_name} #{value} #{timestamp}\n")
        end
      end

      private

      def get_metrics_name(p)
        # Given a properties hash like so
        # {:key=>"cpu_load_avg", :timestamp=>1394801347, :value=>0.25, :tags=>{:ip=>"172.30.5.74", :role=>"core", :job=>"CloudController", :index=>0, :name=>"CloudController/0", :deployment=>"CF"}}
        # One will get a metrics key like so
        # CF.CloudController0.cpu_load_avg
        deployment = p[:tags][:deployment]
        job = p[:tags][:job]
        index = p[:tags][:index]
        ip = p[:tags][:ip].gsub!(".","-")
        key = p[:key]

        unless deployment && job && index && ip && key
          Config.logger.error("collector.create-graphite-key.fail: Could not create metrics name from fields tags.deployment, tags.job, tags.index or key.")
          return nil
        end

        [deployment, job, index, ip, key].join '.'
      end

      def get_value(value)
        unless value.is_a? Numeric
          Config.logger.error("collector.emit-graphite.fail: Value is not a float or int, got: #{value}")
          return nil
        end

        value
      end

      def get_timestamp(ts)
        if ts && is_epoch?(ts)
          return ts
        end

        Time.now.to_i
      end

      def is_epoch?(ts)
        /^1[0-9]{9}$/.match(ts.to_s)
      end

    end
  end
end
