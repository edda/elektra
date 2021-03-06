module ServiceLayer

  class MonitoringService < Core::ServiceLayer::Service

    def driver
      @driver ||= Monitoring::Driver::Fog.new({
        auth_url:   self.auth_url,
        region:     self.region,
        token:      self.token,
        domain_id:  self.domain_id,
        project_id: self.project_id  
      })
    end
    
    def available?(action_name_sym=nil)
      return !current_user.service_url("monitoring").blank?
    end
    
    def alarm_definitions(search = nil)
      alarm_definitions = driver.map_to(Monitoring::AlarmDefinition).alarm_definitions.sort_by(&:name)
      if search
        alarm_definitions = alarm_definitions.select { |ad| 
          ad.name.upcase.match(search.upcase) or 
          ad.description.upcase.match(search.upcase) or
          ad.severity.upcase.match(search.upcase) or
          ad.expression.upcase.match(search.upcase)
        }
      end
      alarm_definitions
    end

    def alarms(options = {})
      search = ""
      if options[:search]
        search = options[:search]
        options.delete(:search)
      end

      alarms = driver.map_to(Monitoring::Alarm).alarms(options)
      
      if search
        alarm_definitions = driver.map_to(Monitoring::AlarmDefinition).alarm_definitions
        alarm_definitions_hash = Hash[alarm_definitions.map{ |a| [a.id, a] }]
        alarms = alarms.select { |alarm| alarm.alarm_definition_name.upcase.match(search.upcase) or 
          alarm_definitions_hash[alarm.alarm_definition_id].description.upcase.match(search.upcase) or
          alarm_definitions_hash[alarm.alarm_definition_id].expression.upcase.match(search.upcase) or
          alarm.used_metrics.upcase.match(search.upcase) 
        }
      end

    end

    def alarm_states_history(id)
      driver.map_to(Monitoring::AlarmState).alarm_states_history(id)
    end

    def notification_methods(search = nil)
      notification_methods = driver.map_to(Monitoring::NotificationMethod).notification_methods
      if search
        notification_methods = notification_methods.select { |nm| nm.name.upcase.match(search.upcase) or nm.address.upcase.match(search.upcase) }
      end
      notification_methods
    end

    def get_alarm_definition(id)
      id.blank? ? nil : driver.map_to(Monitoring::AlarmDefinition).get_alarm_definition(id)
    end

    def get_alarm(id)
      id.blank? ? nil : driver.map_to(Monitoring::Alarm).get_alarm(id)
    end

    def get_notification_method(id)
      id.blank? ? nil : driver.map_to(Monitoring::NotificationMethod).get_notification_method(id)
    end

    def new_notification_method(attributes={})
      Monitoring::NotificationMethod.new(driver,attributes)
    end

    def new_alarm_definition(attributes={})
      Monitoring::AlarmDefinition.new(driver,attributes)
    end
    
    def get_dimension_values_by_dimension(name)
      driver.map_to(Monitoring::Dimension).list_dimension_values(name)[0].values()
    end

    def get_metric(attributes={}) 
      driver.map_to(Monitoring::Metric).list_metrics(attributes)
    end
    
    def get_metric_names(options={})
      metric_names_data = driver.map_to(Monitoring::Metric).list_metric_names(options)
      metric_names = Array.new
      metric_names_data.map{|metric_name_data|metric_names << metric_name_data.name}
      metric_names
    end
    
    def list_statistics(attributes={})
      driver.map_to(Monitoring::Statistic).list_statistics(attributes)[0]
    end

  end
end
