require File.expand_path("../../../spec_helper", File.dirname(__FILE__))

describe Collector::Historian::DataDog do
  describe "sending data to DataDog" do
    let(:datadog_historian) { described_class.new("API_KEY") }
    let(:time) { Time.now.to_i }
    let(:datadog_metric_payload) do
      {
        key: "some_metric.some_key",
        timestamp: time,
        value: 2,
        tags: {
          job: "Test",
          index: 1,
          component: "unknown",
          service_type: "unknown",
          tag: "value",
          foo: %w(bar baz)
        }
      }
    end
    let(:expected_tags) { %w[job:Test index:1 component:unknown service_type:unknown tag:value foo:bar foo:baz] }
    let(:successful_response) { true }
    let(:fake_response) { double(:response, :success? => successful_response) }

    before do
      ::Collector::Config.stub(:deployment_name).and_return("dev114cw")
    end

    it "converts the properties hash into a DataDog point" do
      expected_json = Yajl::Encoder.encode({
        series: [
          {
            metric: "cf.collector.some_metric.some_key",
            points: [[time, 2]],
            type: "gauge",
            tags: expected_tags
          }
        ]
      })
      ::Collector::Config.logger.should_not_receive(:warn)
      HTTParty.should_receive(:post).with("https://app.datadoghq.com/api/v1/series", query: {api_key: "API_KEY"}, body: expected_json, headers: {"Content-type" => "application/json"}).and_return(fake_response)

      datadog_historian.send_data(datadog_metric_payload)
    end

    context "when the passed in data is missing a timestamp" do
      it "uses now" do
        datadog_metric_payload.delete(:timestamp)
        expected_json = Yajl::Encoder.encode({
                                             series: [
                                               {
                                                 metric: "cf.collector.some_metric.some_key",
                                                 points: [[time, 2]],
                                                 type: "gauge",
                                                 tags: expected_tags
                                               }
                                             ]
                                           })
        ::Collector::Config.logger.should_not_receive(:warn)
        HTTParty.should_receive(:post).with("https://app.datadoghq.com/api/v1/series", query: {api_key: "API_KEY"}, body: expected_json, headers: {"Content-type" => "application/json"}).and_return(fake_response)

        Timecop.freeze(Time.at(time)) do
          datadog_historian.send_data(datadog_metric_payload)
        end
      end
    end

    context "when the api request fails" do
      let(:successful_response) { false }

      it "logs" do
        HTTParty.should_receive(:post).and_return(fake_response)

        ::Collector::Config.logger.should_receive(:warn).with("collector.emit-datadog.fail", metric_name: "cf.collector.some_metric.some_key")
        datadog_historian.send_data(datadog_metric_payload)
      end
    end
  end
end