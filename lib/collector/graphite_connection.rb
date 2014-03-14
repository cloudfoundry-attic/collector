module Collector
  # Graphite connection for sending metrics
  class GraphiteConnection < EventMachine::Connection
    def connection_completed
      Config.logger.info("collector.graphite-connected")
      @port, @ip = Socket.unpack_sockaddr_in(get_peername)
    end

    def unbind
      if @port && @ip
        Config.logger.warn("collector.graphite-connection-lost")
        EM.add_timer(1.0) do
          begin
            reconnect(@ip, @port)
          rescue EventMachine::ConnectionError => e
            Config.logger.warn("collector.graphite-connection-error", error: e, backtrace: e.backtrace)
            unbind
          end
        end
      else
        Config.logger.fatal("collector.graphite.could-not-connect")
        exit!
      end
    end

    def receive_data(_)
    end
  end
end
