module Monitoring
  class ApplicationController < DashboardController
    authorization_context 'monitoring'

    def index
    end
  end
end
