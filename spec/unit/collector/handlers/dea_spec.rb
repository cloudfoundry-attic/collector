require 'spec_helper'

describe Collector::Handler::Dea do

  describe "#additional_tags" do
    it "tags metrics with the stack type" do
      context = Collector::HandlerContext.new(nil, nil, {"stacks" => ["Linux", "Windows"]})
      handler = Collector::Handler::Dea.new(nil, nil)

      # note stacks in the varz becomes stack singular in the tags
      handler.additional_tags(context).should == {
        stack: ["Linux", "Windows"]
      }
    end
  end

  describe "process" do
    let(:context) { Collector::HandlerContext.new(nil, nil, varz) }
    let(:varz) { fixture(:dea) }

    before do
      handler.stub(:send_metric)
    end

    subject(:handler) { Collector::Handler::Dea.new(nil, nil) }

    def process
      handler.process(context)
    end

    it "sends the uptime metric converted to seconds" do
      uptime_in_seconds = 56 + (60 * 3) + (60 * 60 * 3) + (60 * 60 * 24 * 3)
      handler.should_receive(:send_metric).with("uptime", uptime_in_seconds, context)
      process
    end

    it "sends the can_stage metric" do
      handler.should_receive(:send_metric).with("can_stage", 1, context)
      process
    end

    it "sends the reservable stagers metric" do
      handler.should_receive(:send_metric).with("reservable_stagers", 28, context)
      process
    end

    it "sends the resource availability metrics" do
      handler.should_receive(:send_metric).with("available_disk_ratio", 1.234, context)
      handler.should_receive(:send_metric).with("available_memory_ratio", 5.678, context)
      process
    end

    it "sends registry metrics" do
      handler.should_receive(:send_metric).with("dea_registry_born", 1, context)
      handler.should_receive(:send_metric).with("dea_registry_running", 2, context)
      handler.should_receive(:send_metric).with("dea_registry_starting", 1, context)
      handler.should_receive(:send_metric).with("dea_registry_stopping", 1, context)
      handler.should_receive(:send_metric).with("dea_registry_stopped", 1, context)
      handler.should_receive(:send_metric).with("dea_registry_crashed", 1, context)
      handler.should_receive(:send_metric).with("dea_registry_deleted", 1, context)
      handler.should_receive(:send_metric).with("dea_registry_resuming", 1, context)
      process
    end

    it "includes born, running, starting and resuming (not sure) in mem and disk usage" do
      handler.should_receive(:send_metric).with("dea_registry_mem_reserved", 256 * 5, context)
      handler.should_receive(:send_metric).with("dea_registry_disk_reserved", 1024 * 5, context)
      process
    end
  end
end
