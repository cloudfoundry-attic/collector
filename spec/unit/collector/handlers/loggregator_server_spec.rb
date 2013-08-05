require 'spec_helper'

describe Collector::Handler::Router do

  class FakeHistorian
    attr_reader :sent_data

    def initialize
      @sent_data = []
    end

    def send_data(data)
      @sent_data << data
    end

    def has_sent_data?(key, value, tags={})
      @sent_data.any? do |data|
        data[:key] == key && data[:value] == value &&
            data[:tags] == data[:tags].merge(tags)
      end
    end
  end

  let(:historian) { FakeHistorian.new }
  let(:timestamp) { 123456789 }
  let(:handler) { Collector::Handler::LoggregatorServer.new(historian, "job") }
  let(:context) { Collector::HandlerContext.new(1, timestamp, varz) }

  describe "process" do
    let(:varz) do
      {
          "name" => "LoggregatorServer",
          "numCPUS" => 1,
          "contexts" => [
              {"name" => "agentListener",
               "metrics" => [
                   {"name" => "currentBufferCount", "value" => 12},
                   {"name" => "receivedMessageCount", "value" => 45},
                   {"name" => "receivedByteCount", "value" => 6}]},
              {"name" => "sinkServer",
               "metrics" => [
                   {"name" => "numberOfSinks", "value" => 9}
               ]
              }
          ]
      }
    end


    it "sends the metrics" do
      handler.process(context)
      historian.should have_sent_data("LoggregatorServer.numCpus", 1)
      historian.should have_sent_data("LoggregatorServer.agentListener.currentBufferCount", 12)
      historian.should have_sent_data("LoggregatorServer.agentListener.receivedMessageCount", 45)
      historian.should have_sent_data("LoggregatorServer.agentListener.receivedByteCount", 6)
      historian.should have_sent_data("LoggregatorServer.sinkServer.numberOfSinks", 9)
    end
  end
end
