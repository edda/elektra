module Monitoring
  module Driver
    class Interface < Core::ServiceLayer::Driver::Base
      
      def alarm_definitions
        raise Core::ServiceLayer::Errors::NotImplemented
      end

      def get_alarm_definition(id)
        raise Core::ServiceLayer::Errors::NotImplemented
      end

      def get_alarm(id)
        raise Core::ServiceLayer::Errors::NotImplemented
      end

      def delete_alarm_definition(id)
        raise Core::ServiceLayer::Errors::NotImplemented
      end

      def delete_alarm(id)
        raise Core::ServiceLayer::Errors::NotImplemented
      end

      def notification_methods
        raise Core::ServiceLayer::Errors::NotImplemented
      end

      def alarms(options={})
        raise Core::ServiceLayer::Errors::NotImplemented
      end

      def alarm_states_history(id, options={})
        raise Core::ServiceLayer::Errors::NotImplemented
      end

      def create_notification_method(options={})
        raise Core::ServiceLayer::Errors::NotImplemented
      end

      def create_alarm_definition(options={})
        raise Core::ServiceLayer::Errors::NotImplemented
      end

      def get_notification_method(id)
        raise Core::ServiceLayer::Errors::NotImplemented
      end

      def update_notification_method(id,options)
        raise Core::ServiceLayer::Errors::NotImplemented
      end

      def update_alarm_definition(id,options)
        raise Core::ServiceLayer::Errors::NotImplemented
      end

      def list_metrics(options={})
        raise Core::ServiceLayer::Errors::NotImplemented
      end

      def list_metric_names(options={})
        raise Core::ServiceLayer::Errors::NotImplemented
      end

      def list_statistics(options={})
        raise Core::ServiceLayer::Errors::NotImplemented
      end
      
      def list_dimension_values(dimension_name,options={})
        raise Core::ServiceLayer::Errors::NotImplemented
      end

    end
  end
end
