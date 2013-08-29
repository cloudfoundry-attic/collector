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
  let(:handler) { Collector::Handler::LoggregatorDeaAgent.new(historian, "job") }
  let(:context) { Collector::HandlerContext.new(1, timestamp, varz) }

  describe "process" do
    let(:varz) do
      {
          "name" => "LoggregatorDeaAgent",
          "numCPUS" => 1,
          "numGoRoutines" => 1,
          "memoryStats" => {
            "numBytesAllocatedHeap" => 1024,
            "numBytesAllocatedStack" => 4096,
            "numBytesAllocated" => 2048,
            "numMallocs" => 3,
            "numFrees" => 10,
            "lastGCPauseTimeNS" => 1000
          },
          "contexts" => [
              {"name" => "context1",
               "metrics" => [
                   {"name" => "metric1", "value" => 12},
                   {"name" => "metric2", "value" => 45},
                   {"name" => "metric3", "value" => 6}]},
              {"name" => "context2",
               "metrics" => [
                   {"name" => "metric4", "value" => 9}
               ]
              }
          ]
      }
    end


    it "sends the metrics" do
      handler.process(context)
      historian.should have_sent_data("LoggregatorDeaAgent.numCpus", 1)
      historian.should have_sent_data("LoggregatorDeaAgent.numGoRoutines", 1)
      historian.should have_sent_data("LoggregatorDeaAgent.memoryStats.numBytesAllocatedHeap", 1024)
      historian.should have_sent_data("LoggregatorDeaAgent.memoryStats.numBytesAllocatedStack", 4096)
      historian.should have_sent_data("LoggregatorDeaAgent.memoryStats.numBytesAllocated", 2048)
      historian.should have_sent_data("LoggregatorDeaAgent.memoryStats.numMallocs", 3)
      historian.should have_sent_data("LoggregatorDeaAgent.memoryStats.numFrees", 10)
      historian.should have_sent_data("LoggregatorDeaAgent.memoryStats.lastGCPauseTimeNS", 1000)
      historian.should have_sent_data("LoggregatorDeaAgent.context1.metric1", 12)
      historian.should have_sent_data("LoggregatorDeaAgent.context1.metric2", 45)
      historian.should have_sent_data("LoggregatorDeaAgent.context1.metric3", 6)
      historian.should have_sent_data("LoggregatorDeaAgent.context2.metric4", 9)
    end
  end
end
