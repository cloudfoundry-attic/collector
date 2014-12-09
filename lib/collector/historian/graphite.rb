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
        # CF.CloudController.0.172-30-5-74.cpu_load_avg
        deployment = p[:tags][:deployment]
        job = p[:tags][:job]
        index = p[:tags][:index]
        ipField = (p[:tags][:ip]|| p[:tags]["ip"])
        ip = ((ipField) ? ipField.gsub(".","-") : "nil" )
        key = p[:key]
        unless deployment && job && index && ip && key
          Config.logger.error("collector.create-graphite-key.fail: Could not create metrics name from fields tags.deployment, tags.job, tags.index or key.")
          return nil
        end
          key = get_keys(p,job)
          [deployment, job, index, ip, key].join '.'
      end

      def get_keys(p, job)
        key = p[:key]
        case job
        when "Router"  
          if key == "router.responses" && (p[:tags].key?("component") || p[:tags].key?(:component))
             key = [p[:key], p[:tags]["component"] || p[:tags][:component] , p[:tags][:status] || p[:tags]["status"] ].join '.'
          end
        end
        return key  
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
