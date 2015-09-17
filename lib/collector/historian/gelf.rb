require "time"
require "gelf"
require "collector/config"

module Collector
  class Historian
    class Gelf
      def initialize(gelf_host, gelf_port)
        @gelf = GELF::Notifier.new(gelf_host, gelf_port)
      end

      def send_data(data)
        @gelf.notify!(data)
      end

    end
  end
end
