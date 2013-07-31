require_relative "./historian/cloud_watch"
require_relative "./historian/data_dog"
require_relative "./historian/tsdb"

module Collector
  class Historian
    def self.build
      historian = new

      if Config.tsdb
        historian.add_adapter(Historian::Tsdb.new(Config.tsdb_host, Config.tsdb_port))
        Config.logger.info("collector.historian-adapter.added-opentsdb", host: Config.tsdb_host)
      end

      if Config.aws_cloud_watch
        historian.add_adapter(Historian::CloudWatch.new(Config.aws_access_key_id, Config.aws_secret_access_key))
        Config.logger.info("collector.historian-adapter.added-cloudwatch")
      end

      if Config.datadog
        historian.add_adapter(Historian::DataDog.new(Config.datadog_api_key))
        Config.logger.info("collector.historian-adapter.added-datadog")
      end

      historian
    end

    def initialize
      @adapters = []
    end

    def send_data(data)
      @adapters.each do |adapter|
        begin
          adapter.send_data(data)
        rescue => e
          Config.logger.warn("collector.historian-adapter.sending-data-error", adapter: adapter.class.name, error: e, backtrace: e.backtrace)
        end
      end
    end

    def add_adapter(adapter)
      @adapters << adapter
    end
  end
end
