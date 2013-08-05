# Copyright (c) 2009-2012 VMware, Inc.

$:.unshift(File.expand_path(".", File.dirname(__FILE__)))

require "base64"
require "set"

require "rubygems"
require "bundler/setup"

require "em-http-request"
require "eventmachine"
require "nats/client"
require "vcap/rolling_metric"

require "collector/config"
require "collector/handler"
require "collector/service_handler"
require "collector/service_node_handler"
require "collector/service_gateway_handler"
require "collector/tsdb_connection"
require "collector/historian"
require "collector/components"

Dir[File.join(File.dirname(__FILE__), "../lib/collector/handlers/*.rb")].each do |file|
  require File.join("collector/handlers", File.basename(file, File.extname(file)))
end

module Collector
  # Varz collector
  class Collector
    ANNOUNCE_SUBJECT = "vcap.component.announce".freeze
    DISCOVER_SUBJECT = "vcap.component.discover".freeze
    COLLECTOR_PING = "collector.nats.ping".freeze

    def initialize
      @components = {}
      @historian = ::Collector::Historian.build
      @nats_latency = VCAP::RollingMetric.new(60)

      NATS.on_error do |e|
        Config.logger.fatal("collector.nats.error", error: e.backtrace)
        exit
      end

      @nats = NATS.connect(:uri => Config.nats_uri) do
        Config.logger.info("collector.nats.connected")
        # Send initially to discover what's already running
        @nats.subscribe(ANNOUNCE_SUBJECT) { |message| process_component_discovery(message) }

        @inbox = NATS.create_inbox
        @nats.subscribe(@inbox) { |message| process_component_discovery(message) }

        @nats.publish(DISCOVER_SUBJECT, "", @inbox)

        @nats.subscribe(COLLECTOR_PING) { |message| process_nats_ping(message.to_f) }

        setup_timers
      end

    end

    # Configures the periodic timers for collecting varzs.
    def setup_timers
      EM.add_periodic_timer(Config.discover_interval) do
        @nats.publish(DISCOVER_SUBJECT, "", @inbox)
      end

      EM.add_periodic_timer(Config.varz_interval) { fetch_varz }
      EM.add_periodic_timer(Config.healthz_interval) { fetch_healthz }
      EM.add_periodic_timer(Config.prune_interval) { prune_components }

      EM.add_periodic_timer(Config.local_metrics_interval) do
        send_local_metrics
      end

      EM.add_periodic_timer(Config.nats_ping_interval) do
        @nats.publish(COLLECTOR_PING, Time.now.to_f.to_s)
      end
    end

    # Processes NATS ping in order to calculate NATS roundtrip latency
    #
    # @param [Float] ping_timestamp UNIX timestamp when the ping was sent
    def process_nats_ping(ping_timestamp)
      @nats_latency << ((Time.now.to_f - ping_timestamp) * 1000).to_i
    end

    # Processes a discovered component message, recording it's location for
    # varz/healthz probes.
    #
    # @param [Hash] message the discovery message
    def process_component_discovery(message)
      message = Yajl::Parser.parse(message)
      if message["index"]
        Config.logger.debug1("collector.component.discovered", type: message["type"], index: message["index"], host: message["host"])
        instances = (@components[message["type"]] ||= {})
        instances[message["index"]] = {
          :host => message["host"],
          :credentials => message["credentials"],
          :timestamp => Time.now.to_i
        }
      end
    rescue => e
      Config.logger.warn("collector.component.discovery-failure", error: e.message, backtrace: e.backtrace)
    end

    # Prunes components that haven't been heard from in a while
    def prune_components
      @components.each do |_, instances|
        instances.delete_if do |_, component|
          Time.now.to_i - component[:timestamp] > Config.prune_interval
        end
      end

      @components.delete_if { |_, instances| instances.empty? }
    rescue => e
      Config.logger.warn("collector.component.pruning-error", error: e.message, backtrace: e.backtrace)
    end

    # Generates metrics that don't require any interactions with varz or healthz
    def send_local_metrics
      context = HandlerContext.new(Config.index, Time.now.to_i, {})
      handler = Handler.handler(@historian, "collector")
      Config.logger.info("collector.nats-latency.sending")
      handler.send_latency_metric("nats.latency.1m", @nats_latency.value, context)
    end

    # Fetches the varzs from all the components and calls the proper {Handler}
    # to record the metrics in the TSDB server
    def fetch_varz
      fetch(:varz) do |http, job, index|
        varz = Yajl::Parser.parse(http.response)
        now = Time.now.to_i

        handler = Handler.handler(@historian, job)
        Config.logger.debug("collector.job.process", job: job, handler: handler)
        ctx = HandlerContext.new(index, now, varz)
        handler.do_process(ctx)
      end
    end

    # Fetches the healthz from all the components and calls the proper {Handler}
    # to record the metrics in the TSDB server
    def fetch_healthz
      fetch(:healthz) do |http, job, index|
        is_healthy = http.response.strip.downcase == "ok" ? 1 : 0
        send_healthz_metric(is_healthy, job, index)
      end
    end

    def credentials_ok?(job, instance)
      unless instance[:credentials].kind_of?(Array)
        Config.logger.warn("collector.credentials.invalid", job: job, instance: instance)
        return false
      end
      true
    end

    # Generates the authorization headers for a specific instance
    #
    # @param [Hash] instance hash
    # @return [Hash] headers
    def authorization_headers(instance)
      credentials = Base64.strict_encode64(instance[:credentials].join(":"))

      {
        "Authorization" => "Basic #{credentials}"
      }
    end

    private

    def fetch(type)
      @components.each do |job, instances|
        instances.each do |index, instance|
          next unless credentials_ok?(job, instance)

          host = instance[:host]
          uri = "http://#{host}/#{type}"

          Config.logger.debug(
            "collector.#{type}.update",
            :host => host, :index => index, :uri => uri,
            :instance => instance.inspect)

          http = EventMachine::HttpRequest.new(uri).get(
            :head => authorization_headers(instance))

          http.errback do
            Config.logger.warn(
              "collector.#{type}.failed",
              :host => host, :error => http.error)
          end

          http.callback do
            begin
              yield http, job, index
            rescue => e
              Config.logger.error(
                "collector.#{type}.processing-failed",
                :error => e, :backtrace => e.backtrace)
            end
          end
        end
      end
    end

    def send_healthz_metric(is_healthy, job, index)
      Config.logger.info("collector.healthz-metrics.sending", job: job, index: index)
      @historian.send_data({
        key: "healthy",
        timestamp: Time.now.to_i,
        value: is_healthy,
        tags: Components.get_job_tags(job).merge({job: job, index: index, deployment: Config.deployment_name})
      })
    end

  end
end
