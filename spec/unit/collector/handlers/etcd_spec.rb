require 'spec_helper'

describe Collector::Handler::Etcd do
  let(:historian) { FakeHistorian.new }
  let(:timestamp) { 123456789 }
  let(:handler) { Collector::Handler::Etcd.new(historian, "job") }
  let(:context) { Collector::HandlerContext.new(1, timestamp, varz) }

  describe "process" do
    let(:varz) { fixture(:etcd) }

    it "sends the metrics" do
      handler.process(context)
      historian.should have_sent_data("etcd.leader.SomeValueA", 40)
      historian.should have_sent_data("etcd.leader.SomeValueB", 41, "foo" => "bar")
      historian.should have_sent_data("etcd.server.SomeValueA", 40)
      historian.should have_sent_data("etcd.server.SomeValueB", 41, "foo" => "bar")
      historian.should have_sent_data("etcd.store.SomeValueA", 40)
      historian.should have_sent_data("etcd.store.SomeValueB", 41, "foo" => "bar")
    end
  end
end
