require File.expand_path("../../../spec_helper", File.dirname(__FILE__))

describe Collector::Historian::Graphite do
  describe "initialization" do
    it "connects to EventMachine" do
      EventMachine.should_receive(:connect).with("host", 9999, Collector::GraphiteConnection)

      described_class.new("host", 9999)
    end
  end

  describe "sending data to Graphite" do
    let(:connection) { double('EventMachine connection') }
    let(:metric_payload) do
      {
        key: "some_key",
        timestamp: 1234568912,
        value: 2,
        tags: {
          :deployment => "CF",
          :name => "Blurgh/0"
        }
      }
    end

    before do
      EventMachine.stub(:connect).and_return(connection)
    end

    it "converts the properties hash graphite data" do
      graphite_historian = described_class.new("host", 9999)

      connection.should_receive(:send_data).with("CF.Blurgh0.some_key 2 1234568912")
      graphite_historian.send_data(metric_payload)
    end

    context "when the passed in data is missing a timestamp" do
      it "uses now" do
        graphite_historian = described_class.new("host", 9999)
        metric_payload.delete(:timestamp)
        Timecop.freeze Time.now.to_i do
          connection.should_receive(:send_data).with("CF.Blurgh0.some_key 2 #{Time.now.to_i}")
          graphite_historian.send_data(metric_payload)
        end
      end
    end

    context "when the passed in data has wrongly formatted timestamp" do
      it "uses now" do
        graphite_historian = described_class.new("host", 9999)

        metric_payload.update(:timestamp => "BLURGh!!11")
        Timecop.freeze Time.now.to_i do
          connection.should_receive(:send_data).with("CF.Blurgh0.some_key 2 #{Time.now.to_i}")
          graphite_historian.send_data(metric_payload)
        end
      end
    end

    context "when the value is not a int or float" do
      it "should log and not do anything" do
        graphite_historian = described_class.new("host", 9999)
        metric_payload.update(:value => "BLURGh!!11")
        ::Collector::Config.logger.should_receive(:error).with("collector.emit-graphite.fail: Value is not a float or int, got: BLURGh!!11")
        graphite_historian.send_data(metric_payload)
      end
    end

  end
end
