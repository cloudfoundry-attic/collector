# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  # TSDB connection for sending metrics
  class TsdbConnection < EventMachine::Connection
    def connection_completed
      Config.logger.info("Connected to TSDB server")
      @port, @ip = Socket.unpack_sockaddr_in(get_peername)
    end

    def unbind
      if @port && @ip
        Config.logger.warn("Lost connection to TSDB server, reconnecting")
        EM.add_timer(1.0) do
          begin
            reconnect(@ip, @port)
          rescue EventMachine::ConnectionError => e
            Config.logger.warn(e)
            unbind
          end
        end
      else
        Config.logger.fatal("Couldn't connect to TSDB server, exiting.")
        exit!
      end
    end

    def receive_data(data)
      Config.logger.debug("Received from TSDB: #{data}")
    end
  end
end
