module Collector
  # TSDB connection for sending metrics
  class TsdbConnection < EventMachine::Connection
    def connection_completed
      Config.logger.info("collector.tsdb-connected")
      @port, @ip = Socket.unpack_sockaddr_in(get_peername)
    end

    def unbind
      if @port && @ip
        Config.logger.warn("collector.tsdb-connection-lost")
        EM.add_timer(1.0) do
          begin
            reconnect(@ip, @port)
          rescue EventMachine::ConnectionError => e
            Config.logger.warn("collector.tsdb-connection-error", error: e, backtrace: e.backtrace)
            unbind
          end
        end
      else
        Config.logger.fatal("collector.tsdb.could-not-connect")
        exit!
      end
    end

    def receive_data(_)
    end
  end
end
