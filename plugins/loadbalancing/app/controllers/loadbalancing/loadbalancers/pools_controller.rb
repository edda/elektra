module Loadbalancing
  module Loadbalancers
    class PoolsController < DashboardController

      before_filter :load_objects

      def index
        # get all pools for project and calc. quota
        @pools = services.loadbalancing.pools(tenant_id: @scoped_project_id)
        @quota_data = services.resource_management.quota_data([{service_name: :loadbalancing, resource_name: :pools, usage: @pools.length}])
        # delete pool from different loadbalancers
        @pools.reject! { |p| p.loadbalancers.first['id'] != @loadbalancer.id }
      end

      def show_all
        @members = services.loadbalancing.pool_members(@pool.id) if @pool
        @healthmonitor = services.loadbalancing.find_healthmonitor(@pool.healthmonitor_id) if @pool and @pool.healthmonitor_id
      end

      def show_details
        @members = services.loadbalancing.pool_members(@pool.id) if @pool
        begin
          @healthmonitor = services.loadbalancing.find_healthmonitor(@pool.healthmonitor_id) if @pool and @pool.healthmonitor_id
        rescue
          @healthmonitor = nil
        end

      end

      def new
        @pool = services.loadbalancing.new_pool
        @listeners = services.loadbalancing.listeners(tenant_id: @scoped_project_id).keep_if { |l| l.default_pool_id.blank? }
        @listeners.reject! { |l| l.loadbalancers.first['id'] != @loadbalancer.id } if @listeners
        @loadbalancers = [@loadbalancer]
        if params[:listener_id]
          @listener = services.loadbalancing.find_listener(params[:listener_id])
          @pool.listener = @listener if @listener
        end
        @pool.protocol = params[:proto] if params[:proto] && params[:proto] != 'TERMINATED_HTTPS'
        @pool.protocol = 'HTTP' if params[:proto] && params[:proto] == 'TERMINATED_HTTPS'
      end

      def create
        @pool = services.loadbalancing.new_pool
        @pool.attributes = pool_params.delete_if { |key, value| value.blank? }.merge(session_persistence)
        if @pool.save
          audit_logger.info(current_user, "has created", @pool)
          # render template: 'loadbalancing/loadbalancers/pools/update_item_with_close.js'
          redirect_to loadbalancer_pools_path(loadbalancer_id: @loadbalancer.id), notice: 'Pool was successfully created.'
        else
          @loadbalancers = [@loadbalancer]
          @listeners = services.loadbalancing.listeners(tenant_id: @scoped_project_id).keep_if { |l| l.default_pool_id.blank? }
          @listeners.reject! { |l| l.loadbalancers.first['id'] != @loadbalancer.id } if @listeners
          render :new
        end
      end

      def edit
        @listeners = services.loadbalancing.listeners(tenant_id: @scoped_project_id)
        @loadbalancers = services.loadbalancing.loadbalancers(tenant_id: @scoped_project_id)
      end

      def update
        update_params = pool_params.merge!(session_persistence)
        listener_id = @pool.listeners.first['id'] if @pool.listeners.first
        if @pool.update(update_params)
          listener = services.loadbalancing.find_listener(listener_id) if listener_id
          @pool.listener = listener
          @pool.loadbalancer = @loadbalancer
          @listeners = services.loadbalancing.listeners()
          @loadbalancers = services.loadbalancing.loadbalancers(tenant_id: @scoped_project_id)
          audit_logger.info(current_user, "has updated", @pool)
          render template: 'loadbalancing/loadbalancers/pools/update_item_with_close.js'
          #redirect_to pool_path(@pool.id), notice: 'Pool was successfully updated.'
        else
          render :edit
        end
      end

      def destroy
        @pool = services.loadbalancing.find_pool(params[:id])
        @healthmonitor = services.loadbalancing.find_healthmonitor(@pool.healthmonitor_id) if @pool.healthmonitor_id

        count = 0
        h_error = false
        if @healthmonitor
          until @healthmonitor.destroy
            if count > 10
              h_error = true
              break
            end
            count += 1
            sleep 1
          end
        end

        if h_error
          redirect_to loadbalancer_pools_path(loadbalancer_id: @loadbalancer.id), flash: {error: "Could not delete attached Healthmonitor #{@healthmonitor.errors.full_messages.to_sentence}"}
          return
        end

        count = 0
        p_error = false
        until @pool.destroy
          if count > 10
            p_error = true
            break
          end
          count += 1
          sleep 1
        end

        sleep 3
        if !p_error and !h_error and @healthmonitor
          audit_logger.info(current_user, "has deleted", @pool)
          audit_logger.info(current_user, "has deleted", @healthmonitor)
          redirect_to request.referer, notice: 'Pool and Healthmonitor successfully deleted.'
        elsif !p_error and !h_error and !@healthmonitor
          audit_logger.info(current_user, "has deleted", @pool)
          redirect_to request.referer, notice: 'Pool successfully deleted.'
        else
          redirect_to request.referer, flash: {error: "Pool deletion failed -> #{@pool.errors.full_messages.to_sentence}"}
        end
      end

      private

      def load_objects
        @pool = services.loadbalancing.find_pool(params[:id]) if params[:id]
        @loadbalancer = services.loadbalancing.find_loadbalancer(params[:loadbalancer_id]) if params[:loadbalancer_id]
        if @pool
          @listener = services.loadbalancing.find_listener(@pool.listeners.first['id']) if @pool.listeners.first
          @pool.listener = @listener if @listener
          @pool.loadbalancer = @loadbalancer if @loadbalancer
        end
      end

      def pool_params
        return params[:pool]
      end

      def session_persistence
        session_persistence = {session_persistence: {}}
        unless pool_params['session_persistence_type'].blank?
          session_persistence[:session_persistence].merge!({type: pool_params.delete('session_persistence_type')})
          if session_persistence[:session_persistence][:type] == 'APP_COOKIE'
            session_persistence[:session_persistence].merge!({cookie_name: pool_params.delete('session_persistence_cookie_name')})
          end
        end
        return session_persistence
      end

    end
  end
end
