module Collector
  class Handler
    class LoggregatorDeaAgent < Handler
      def process(context)
        varz_message = context.varz
        component_name = varz_message['name']

        send_metric("#{component_name}.numCpus", varz_message['numCPUS'], context)
        send_metric("#{component_name}.numGoRoutines", varz_message['numGoRoutines'], context)

        varz_message["memoryStats"].each_pair do |mem_stat_name, mem_stat_value|
          send_metric("#{component_name}.memoryStats.#{mem_stat_name}", mem_stat_value, context)
        end

        varz_message['contexts'].each do |message_context|
          context_name = message_context['name']
          message_context['metrics'].each do |metric|
            metric_name = metric['name']
            metric_value = metric['value']
            metric_tags = metric['tags'] || {}
            send_metric("#{component_name}.#{context_name}.#{metric_name}", metric_value, context, metric_tags)
          end
        end
      end

      private

      register Components::LOGGREGATOR_DEA_AGENT_COMPONENT
    end
  end
end
