module Compute
  class FlavorAccess < Core::ServiceLayer::Model
    def save
      # execute before callback
      before_save

      success = self.valid?
      if success
        begin
          @driver.add_flavor_access_to_tenant(self.flavor_id,self.tenant_id)
        rescue => e
          raise e unless defined?(@driver.handle_api_errors?) and @driver.handle_api_errors?
          Core::ServiceLayer::ApiErrorHandler.get_api_error_messages(e).each{|message| self.errors.add(:api, message)}
          success = false
        end
      end
      return success & after_save
    end
    
    def destroy
      before_destroy
      begin
        @driver.remove_flavor_access_from_tenant(flavor_id, tenant_id)
        return true
      rescue => e
        raise e unless defined?(@driver.handle_api_errors?) and @driver.handle_api_errors?
        Core::ServiceLayer::ApiErrorHandler.get_api_error_messages(e).each{|message| self.errors.add(:api, message)}
        return false
      end
    end    
  end
end