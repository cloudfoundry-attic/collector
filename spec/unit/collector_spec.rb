# Copyright (c) 2009-2012 VMware, Inc.

require File.expand_path("../spec_helper", File.dirname(__FILE__))

describe Collector::Collector do
  let(:collector) do
    Collector::Config.tsdb_host = "dummy"
    Collector::Config.tsdb_port = 14242
    Collector::Config.nats_uri = "nats://foo:bar@nats-host:14222"
    EventMachine.stub(:connect)
    NATS.stub(:connect)
    Collector::Collector.new
  end

  def stub_em_http
    http_request = MockRequest.new
    EventMachine::HttpRequest.stub_chain(:new, get: http_request)
    http_request
  end

  describe "component discovery" do
    it "should record components when they announce themeselves" do
      create_fake_collector do |collector, _|
        components = collector.instance_eval { @components }
        components.should be_empty

        Time.should_receive(:now).at_least(1).and_return(Time.at(1311979380))

        collector.process_component_discovery(Yajl::Encoder.encode({
          "type" => "Test",
          "index" => 1,
          "host" => "test-host:1234",
          "credentials" => ["user", "pass"]
        }))

        components.should == {
          "Test"=> {
            "test-host" => {
              :host => "test-host:1234",
              :index => 1,
              :credentials => ["user", "pass"],
              :timestamp => 1311979380
            }
          }
        }
      end
    end
  end

  describe "pruning components" do
    it "should prune old components" do
      create_fake_collector do |collector, _, _|
        Collector::Config.prune_interval = 10

        components = collector.instance_eval { @components }
        components.should be_empty

        collector.process_component_discovery(Yajl::Encoder.encode({
          "type" => "Test",
          "index" => 1,
          "host" => "test-host-1:1234",
          "credentials" => ["user", "pass"]
        }))

        collector.process_component_discovery(Yajl::Encoder.encode({
          "type" => "Test",
          "index" => 2,
          "host" => "test-host-2:1234",
          "credentials" => ["user", "pass"]
        }))

        components["Test"]["test-host-1"][:timestamp] = 100000
        components["Test"]["test-host-2"][:timestamp] = 100005

        Time.should_receive(:now).at_least(1).and_return(Time.at(100011))

        collector.prune_components

        components.should == {
          "Test"=> {
            "test-host-2" => {
              :host=>"test-host-2:1234",
              :index => 2,
              :credentials=>["user", "pass"],
              :timestamp=>100005
            }
          }
        }
      end
    end
  end

  describe "fetch varz" do
    before do
      collector.process_component_discovery(Yajl::Encoder.encode(
                                                "type" => "Test",
                                                "index" => 0,
                                                "host" => "test-host:1234",
                                                "credentials" => ["user", "pass"]
                                            ))
    end

    subject(:fetch_varz) { collector.fetch_varz }

    context "when a normal varz returns succesfully" do
      it "hits the correct endpoint" do
        http_conn = mock(:http_conn)
        EventMachine::HttpRequest.should_receive(:new).with("http://test-host:1234/varz") { http_conn }
        http_conn.should_receive(:get).with(head: { "Authorization" => "Basic dXNlcjpwYXNz" }) { mock.as_null_object }

        fetch_varz
      end

      it "gives the message to the correct handler" do
        Timecop.freeze(Time.now) do
          request = stub_em_http
          fetch_varz

          request.stub(:response) { '{"foo": "bar"}' }
          handler = mock(:handler)
          Collector::Handler.should_receive(:handler).with(anything, anything) { handler }
          handler.should_receive(:do_process).with(Collector::HandlerContext.new(0, Time.now.to_i, { "foo" => "bar" }))

          request.call_callback
        end
      end
    end

    context "when the varz has json errors" do
      it 'should log the error' do
        request = stub_em_http
        fetch_varz

        Collector::Config.logger.stub(:warn).with(/\AError processing varz: lexical error: .*?; fetched from test-host:1234\z/m)
        Collector::Config.logger.stub(:warn).with(instance_of(Yajl::ParseError))

        request.stub(:response) { 'foo' }
        request.call_callback
      end
    end

    context "when the varz does not return succefully" do
      it "should log the failure" do
        request = stub_em_http
        request.stub(error: "404 not found")

        fetch_varz

        Collector::Config.logger.stub(:warn).with(
          "collector.varz.failed",
          :host => "test-host:1234", :error => "404 not found")

        request.call_errback(:foo)
      end
    end
  end

  describe "fetch healthz" do
    before do
      collector.process_component_discovery(Yajl::Encoder.encode(
        "type" => "Test",
        "index" => 0,
        "host" => "test-host:1234",
        "credentials" => ["user", "pass"]
      ))
    end

    subject(:fetch_healthz) { collector.fetch_healthz }

    context "when a normal healthz returns succesfully" do
      before { Collector::Config.stub(:deployment_name).and_return("the_deployment") }

      it "hits the correct endpoint" do
        http_conn = mock(:http_conn)
        EventMachine::HttpRequest.should_receive(:new).with("http://test-host:1234/healthz") { http_conn }
        http_conn.should_receive(:get).with(head: { "Authorization" => "Basic dXNlcjpwYXNz" }) { mock.as_null_object }

        fetch_healthz
      end

      it "directly sends the bad health out" do
        Timecop.freeze(Time.now) do
          request = stub_em_http
          fetch_healthz

          request.stub(:response) { 'bad' }
          Collector::Historian.any_instance.should_receive(:send_data).with(
            key: "healthy",
            timestamp: Time.now.to_i,
            value: 0,
            tags: {job: "Test", index: 0, deployment: "the_deployment"}
          )

          request.call_callback
        end
      end

      it "directly sends the good health out" do
        Timecop.freeze(Time.now) do
          request = stub_em_http
          fetch_healthz

          request.stub(:response) { 'ok' }
          Collector::Historian.any_instance.should_receive(:send_data).with(
            key: "healthy",
            timestamp: Time.now.to_i,
            value: 1,
            tags: {job: "Test", index: 0, deployment: "the_deployment"}
          )

          request.call_callback
        end
      end
    end

    context "when the healthz does not return succefully" do
      it "should log the failure" do
        request = stub_em_http
        request.stub(error: "404 not found")

        fetch_healthz

        Collector::Config.logger.stub(:warn).with(
          "collector.healthz.failed",
          :host => "test-host:1234", :error => "404 not found")

        request.call_errback(:foo)
      end
    end
  end

  describe "local metrics" do
    def send_local_metrics
      Time.stub!(:now).and_return(1000)

      create_fake_collector do |collector, _, _|
        collector.process_nats_ping(997)
        collector.process_nats_ping(998)
        collector.process_nats_ping(999)

        handler = mock(:Handler)
        yield handler

        Collector::Handler.should_receive(:handler).
          with(kind_of(Collector::Historian), "collector").
          and_return(handler)

        collector.send_local_metrics
      end
    end

    it "should send nats latency rolling metric" do
      send_local_metrics do |handler|
        latency = {:value => 6000, :samples => 3}
        handler.should_receive(:send_latency_metric).with("nats.latency.1m", latency, kind_of(Collector::HandlerContext))
      end
    end
  end

  describe "authorization headers" do
    it "should correctly encode long credentials (no CR/LF)" do
      create_fake_collector do |collector, _, _|
        collector.authorization_headers({:credentials => ["A" * 64, "B" * 64]}).
            should == {
              "Authorization" =>
                 "Basic QUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFB" +
                   "QUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQTpCQkJCQkJC" +
                   "QkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJC" +
                   "QkJCQkJCQkJCQkJCQkJCQkJCQkJC"}
      end
    end
  end

  describe "nats latency" do
    let(:historian) { double(:historian) }

    it 'should report metrics' do
      Collector::Historian.stub(:build).and_return(historian)
      collector.process_nats_ping((Time.now + 50).to_f)

      historian.should_receive(:send_data)
      collector.send_local_metrics
    end
  end
end
