# Copyright (c) 2009-2012 VMware, Inc.
module Collector
  class Handler
    class HealthManager < Handler
      def process(context)
        varz = context.varz
        total_varz = varz["total"]
        send_metric("total.apps", total_varz["apps"], context)
        send_metric("total.started_apps", total_varz["started_apps"], context)
        send_metric("total.instances", total_varz["instances"], context)
        send_metric("total.started_instances", total_varz["started_instances"], context)
        send_metric("total.memory", total_varz["memory"], context)
        send_metric("total.started_memory", total_varz["started_memory"], context)

        running_varz = varz["running"]
        send_metric("running.crashes", running_varz["crashes"], context)
        send_metric("running.running_apps", running_varz["apps"], context)
        send_metric("running.running_instances", running_varz["running_instances"], context)
        send_metric("running.missing_instances", running_varz["missing_instances"], context)
        send_metric("running.flapping_instances", running_varz["flapping_instances"], context)

        send_metric("time_to_analyze_all_droplets_in_seconds", varz["analysis_loop_duration"], context)
        send_metric("time_to_retrieve_desired_state_in_seconds", varz["bulk_update_loop_duration"], context)

        send_metric("total_heartbeat_messages_received", varz["heartbeat_msgs_received"], context)
        send_metric("total_droplet_exited_messages_received", varz["droplet_exited_msgs_received"], context)
        send_metric("total_droplet_update_messages_received", varz["droplet_updated_msgs_received"], context)
        send_metric("total_hm_status_messages_received", varz["healthmanager_status_msgs_received"], context)
        send_metric("total_hm_health_request_messages_received", varz["healthmanager_health_request_msgs_received"], context)
        send_metric("total_hm_droplet_request_messages_received", varz["healthmanager_droplet_request_msgs_received"], context)

        total_users = varz["total_users"]
        return unless total_users

        if total_users > 0
          send_metric("total_users", total_users, context)

          if @last_num_users
            new_users = total_users - @last_num_users
            rate = new_users.to_f / (context.now - @last_check_timestamp)
            send_metric("user_rate", rate, context)
          end

          @last_num_users = total_users
          @last_check_timestamp = context.now
        end
      end

      register Components::HEALTH_MANAGER_COMPONENT
    end
  end
end
