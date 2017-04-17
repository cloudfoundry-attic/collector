require File.expand_path("../../../spec_helper", File.dirname(__FILE__))

class FakeResponse
  attr_accessor :success

  def initialize(success)
    @success = success
  end

  def success?
    @success
  end
end

class FakeHttpClient
  attr_reader :last_post
  attr_accessor :respond_successfully

  def initialize
    @respond_successfully = true
  end

  def post(path, options)
    @last_post = {
      path: path,
      options: options
    }

    FakeResponse.new(@respond_successfully)
  end

  def reset
    @last_post = nil
  end

  def parsed_post_body
    Yajl::Parser.parse(@last_post[:options][:body])
  end
end

describe Collector::Historian::NewrelicPlugin do
  describe "sending data to Newrelic Plugin" do
    let(:data_threshold) {50}
    let(:time_threshold) {20}
    let(:fake_http_client) {FakeHttpClient.new}
    let(:newrelic_plugin_historian) do
      Timecop.freeze(Time.at(time)) do
        described_class.new("LICENSE_KEY", fake_http_client)
      end
    end
    let(:time) { Time.now.to_i }
    let(:endpoint_url) { "https://platform-api.newrelic.com/platform/v1/metrics" }
    let(:success_message) { "collector.emit-newrelic-plugin.success" }
    let(:fail_message) { "collector.emit-newrelic-plugin.fail" }
    let(:newrelic_plugin_metric_payload) do
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
    let(:expected_tags) do 
      { job: "Test", index: 1, component: "unknown", service_type: "unknown", tag: "value", foo: ["bar", "baz"] }
    end

    before do
      ::Collector::Config.stub(:deployment_name).and_return("dev114cw")
      ::Collector::Config.stub(:newrelic_plugin_data_threshold).and_return(data_threshold)
      ::Collector::Config.stub(:newrelic_plugin_time_threshold_in_seconds).and_return(time_threshold)

      @counter = 0
    end

    def submit_n_events(n)
      n.times do
        newrelic_plugin_historian.send_data(newrelic_plugin_metric_payload.merge({
          value: @counter,
          key: "some_metric.some_key#{@counter}"
        }))
        @counter += 1
      end
    end

    it "aggregates the passed in data and sends the post to data dog once it hits the threshold number of data points" do
      ::Collector::Config.logger.should_not_receive(:warn)
      ::Collector::Config.logger.should_receive(:info).with(success_message, number_of_metrics: data_threshold, lag_in_seconds: 0).twice

      Timecop.freeze(Time.at(time + 1)) do
        submit_n_events(data_threshold - 1)
        fake_http_client.last_post.should be_nil

        submit_n_events(1)
        fake_http_client.last_post[:path].should == endpoint_url
        fake_http_client.last_post[:options][:headers].should == {
          "Content-type" => "application/json",
          "X-License-Key" => "LICENSE_KEY"
        }
        body = fake_http_client.parsed_post_body
        body["components"][0]["metrics"].length.should equal(data_threshold)
        values = body["components"][0]["metrics"].map {|entry| entry[1]}
        values.should eql((0...data_threshold).to_a)

        fake_http_client.reset
        submit_n_events(data_threshold - 1)
        fake_http_client.last_post.should be_nil

        submit_n_events(1)
        body = fake_http_client.parsed_post_body
        body["components"][0]["metrics"].length.should equal(data_threshold)
        values = body["components"][0]["metrics"].map {|entry| entry[1]}
        values.should eql((data_threshold...(2 * data_threshold)).to_a)
      end
    end

    it "aggregates the passed in data and sends the post to newrelic plugin after the threshold time has elapsed" do
      ::Collector::Config.logger.should_not_receive(:warn)
      ::Collector::Config.logger.should_receive(:info).with(success_message, number_of_metrics: 7, lag_in_seconds: 0)

      Timecop.freeze(Time.at(time)) do
        submit_n_events(1)
      end
      fake_http_client.last_post.should be_nil

      Timecop.freeze(Time.at(time + time_threshold - 1)) do
        submit_n_events(5)
      end
      fake_http_client.last_post.should be_nil

      Timecop.freeze(Time.at(time + time_threshold)) do
        submit_n_events(1)
      end

      fake_http_client.last_post[:path].should == endpoint_url
      fake_http_client.last_post[:options][:headers].should == {
        "Content-type" => "application/json",
        "X-License-Key" => "LICENSE_KEY"
      }
      body = fake_http_client.parsed_post_body
      body["components"][0]["metrics"].length.should equal(7)
      values = body["components"][0]["metrics"].map {|entry| entry[1]}
      values.should eql((0...7).to_a)
    end

    it "batches more than once" do
      Timecop.freeze(Time.at(time + time_threshold + 1)) do
        submit_n_events(1)
      end
      fake_http_client.last_post.should_not be_nil

      fake_http_client.reset

      Timecop.freeze(Time.at(time + time_threshold + 5)) do
        submit_n_events(1)
      end
      fake_http_client.last_post.should be_nil

      Timecop.freeze(Time.at(time + time_threshold + time_threshold + 1)) do
        submit_n_events(1)
      end
      fake_http_client.last_post.should_not be_nil
    end

    it "converts the properties hash into a Newrelic Plugin Event" do
      ::Collector::Config.logger.should_not_receive(:warn)
      ::Collector::Config.logger.should_receive(:info).with(success_message, number_of_metrics: 1, lag_in_seconds: 0)

      Timecop.freeze(Time.at(time + time_threshold)) do
        newrelic_plugin_historian.send_data(newrelic_plugin_metric_payload)
      end

      expected_result = {
        agent: {
          host: "dev114cw",
          version: "1"
        },
        components: [{
          name: "dev114cw",
          guid: "dev114cw",
          duration: 20,
          metrics: {
           "Component/some_metric/some_key" => 2
          }
        }]
      }

      expected_json = Yajl::Encoder.encode(expected_result)

      fake_http_client.last_post[:path].should == endpoint_url
      fake_http_client.last_post[:options][:headers].should == {
        "Content-type" => "application/json",
        "X-License-Key" => "LICENSE_KEY"
      }
      fake_http_client.last_post[:options][:body].should == expected_json
    end

    context "when the api request fails" do
      it "logs" do
        fake_http_client.respond_successfully = false
        ::Collector::Config.logger.should_not_receive(:info)
        ::Collector::Config.logger.should_receive(:warn).with(fail_message, number_of_metrics: 1, lag_in_seconds: 0)

        Timecop.freeze(Time.at(time + time_threshold)) do
          newrelic_plugin_historian.send_data(newrelic_plugin_metric_payload)
        end
      end
    end

    it "logs the lag between requesting to send and actually sending" do
      ::Collector::Config.logger.should_receive(:info).with(success_message, number_of_metrics: 1, lag_in_seconds: 5)

      block = nil
      EM.should_receive(:defer) do |&blk|
        block = blk
      end

      Timecop.freeze(Time.at(time + time_threshold)) do
        newrelic_plugin_historian.send_data(newrelic_plugin_metric_payload)
      end

      Timecop.freeze(Time.at(time + time_threshold + 5)) do
        block.call
      end
    end
  end
end