module Monitoring
  module Driver
    class Fog < Interface
      include Core::ServiceLayer::FogDriver::ClientHelper

      def initialize(params_or_driver)
        # support initialization by given driver
        if params_or_driver.is_a?(::Fog::Monitoring::OpenStack)
          @fog = params_or_driver
        else
          super(params_or_driver)
          # don't include useless request/response dumps in exception messages
          no_debug = { debug: false, debug_request: false, debug_response: false}
          @fog = ::Fog::Monitoring::OpenStack.new(auth_params.merge(connection_options: no_debug))
        end
      end

      def handle_api_errors?
        # to handle the errors withing the plugin (inside the application_controller)
        # otherwise all errors will be swallowed by the service layer
        false
      end

      def alarm_definitions
        handle_response do
          @fog.list_alarm_definitions.body["elements"]
        end
      end

      def alarms
        handle_response do
          @fog.list_alarms.body["elements"]
        end
      end

      def get_alarm_definition(id)
        handle_response do
          @fog.get_alarm_definition(id).body
        end
      end

      def get_notification_method(id)
        handle_response do
          @fog.get_notification_method(id).body
        end
      end

      def delete_notification_method(id)
        handle_response do
          @fog.delete_notification_method(id).body
        end
      end

      def update_notification_method(id, params={})
        handle_response do
          # TODO: use her "map_attribute_names" like we used in object storage?
          request_params = {"name" => params["name"],"type" => params["type"], "address" => params["address"]}
          @fog.update_notification_method(id, request_params).body
        end
      end

      def delete_alarm_definition(id)
        handle_response do
          @fog.delete_alarm_definition(id).body
        end
      end

      def notification_methods
        handle_response do
          @fog.list_notification_methods.body["elements"]
        end
      end

      def create_notification_method(params={})
        handle_response do
          @fog.create_notification_method(params).body
        end
      end
    end
  end
end

