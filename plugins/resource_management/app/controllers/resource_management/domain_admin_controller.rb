require_dependency "resource_management/application_controller"

module ResourceManagement
  class DomainAdminController < ::ResourceManagement::ApplicationController

    before_filter :load_project_resource, only: [:edit, :cancel, :update]
    before_filter :load_domain_resource, only: [:new_request, :create_request, :edit_default_quota, :update_default_quota]
    before_filter :load_inquiry, only: [:review_request, :approve_request]

    authorization_required

    def index
      @all_services = ResourceManagement::ServiceConfig.all.map(&:name)
      prepare_data_for_resource_list(@all_services, overview: true)

      respond_to do |format|
        format.html
        format.js # update only status bars 
      end
    end

    def edit_default_quota
      @default_quota = nil;
      if @resource.default_quota
        previous_value = params[:resource] ? params[:resource][:default_quota] : nil
        @default_quota = previous_value || @resource.data_type.format(@resource.default_quota)
      end
    end

    def update_default_quota
      if @resource.update(params.require(:resource).permit(:default_quota))
        render 'update_default_quota'
      else
        @has_errors = true
        render action: :edit_default_quota
      end
    end

    def show_area
      @area = params.require(:area).to_sym
      @area_services = ResourceManagement::ServiceConfig.in_area(@area).map(&:name)
      prepare_data_for_resource_list(@area_services)

      respond_to do |format|
        format.html
        format.js # update only status bars
      end
 
    end

    def edit
    end

    def cancel
      respond_to do |format|
        format.js { render action: 'update' }
      end
    end

    def update
      # validate new quota value
      value = params.require(:value)
      begin
        value = @project_resource.data_type.parse(value)
        raise ArgumentError, 'New quota may not be lower than current usage!' if value < @project_resource.usage
      rescue ArgumentError => e
        render text: e.message, status: :bad_request
        return
      end

      # do only a upgrade if the values are different otherwise it meaningless
      if @project_resource.approved_quota != value || @project_resource.current_quota != value
        @project_resource.approved_quota = value
        @project_resource.current_quota  = value
        services.resource_management.apply_current_quota(@project_resource) # apply quota in target service
        @project_resource.save
      end
      
      # prepare data for view
      prepare_data_for_details_view(@project_resource.service.to_sym, @project_resource.name.to_sym)

      respond_to do |format|
        format.js
      end
    end

    def review_request
      # prepare data for view
      _, _ = prepare_data_for_details_view(@project_resource.service.to_sym, @project_resource.name.to_sym)

      # calculate projected @project_status after approval
      @desired_quota = @inquiry.payload['desired_quota']
      @domain_status_new = {
        usage_sum:                  @resource_status[:usage_sum],
        current_quota_sum:          @resource_status[:current_quota_sum] - @project_resource.approved_quota + @desired_quota,
        domain_resource:            @domain_resource,
        has_infinite_current_quota: @resource_status[:has_infinite_current_quota],
      }
    end

    def approve_request
      value = params.require(:resource).require(:approved_quota)
      # check new value a last time
      begin
        @project_resource.approved_quota = @project_resource.data_type.parse(value)
        @project_resource.current_quota = @project_resource.data_type.parse(value)
      rescue ArgumentError => e
        @project_resource.add_validation_error(:approved_quota, 'is invalid: ' + e.message)
      end

      if @project_resource.save
        comment = "New project quota is #{@project_resource.data_type.format(@project_resource.approved_quota)}"
        if params[:resource][:comment].present?
          comment += ", comment from approver: #{params[:resource][:comment]}"
        end
        services.resource_management.apply_current_quota(@project_resource) # apply quota in target service
        services.inquiry.set_inquiry_state(@inquiry.id, :approved, comment)
      else
        self.review_request
        render action: 'review_request'
      end
    end

    def new_request
      # prepare data for usage display
      prepare_data_for_details_view(@resource.service.to_sym, @resource.name.to_sym)
    end

    def create_request
      # parse and validate value
      old_value = @resource.approved_quota
      data_type = @resource.data_type
      value = params.require(:resource).require(:approved_quota)
      begin
        value = data_type.parse(value)
        @resource.approved_quota = value
        if value <= old_value || data_type.format(value) == data_type.format(old_value)
          # the second condition catches slightly larger values that round to the same representation, e.g. 100.000001 GiB
          @resource.add_validation_error(:approved_quota, 'must be larger than current value')
        end
      rescue ArgumentError => e
        @resource.add_validation_error(:approved_quota, 'is invalid: ' + e.message)
      end

      # back to square one if validation failed
      unless @resource.validate
        @has_errors = true
        # prepare data for usage display
        prepare_data_for_details_view(@resource.service.to_sym, @resource.name.to_sym)
        render action: :new_request
        return
      end

      # create inquiry
      base_url    = plugin('resource_management').cloud_admin_area_path(area: @resource.config.service.area.to_s, domain_id: Rails.configuration.cloud_admin_domain,
                                                                        project_id: Rails.configuration.cloud_admin_project)
      overlay_url = plugin('resource_management').cloud_admin_review_request_path(domain_id: Rails.configuration.cloud_admin_domain,
                                                                                  project_id: Rails.configuration.cloud_admin_project)

      inquiry = services.inquiry.create_inquiry(
        'domain_quota',
        "domain #{@scoped_domain_name}: add #{@resource.data_type.format(value - old_value)} #{@resource.service}/#{@resource.name}",
        current_user,
        {
          resource_id: @resource.id,
          service: @resource.service,
          resource: @resource.name,
          desired_quota: value,
        },
        service_user.list_ccadmins(),
        {
          "approved": {
            "name": "Approve",
            "action": "#{base_url}?overlay=#{overlay_url}",
          },
        },
        nil,
        {
            domain_name: @scoped_domain_name,
            region: current_region
        }
      )
      if inquiry.errors?
        @has_errors = true
        # prepare data for usage display
        prepare_data_for_details_view(@resource.service.to_sym, @resource.name.to_sym)
        render action: :new_request
        return
      end

      respond_to do |format|
        format.js
      end
    end

    def details
      @show_all_button = true if params[:overview] == 'true'

      @service  = params.require(:service).to_sym
      @resource = params.require(:resource).to_sym
      @area     = ResourceManagement::ServiceConfig.find(@service).area

      # some parts of data collection are shared with update()
      project_resources = prepare_data_for_details_view(@service, @resource)

      # prepare the projects table
      projects = project_resources.to_a.sort_by do |project_resource|
        # find warning level for project
        warning_level = view_context.warning_level_for_project(project_resource)
        sort_order    = { "danger" => 0, "warning" => 1 }.fetch(warning_level, 2)
        # sort projects by warning level, then by name
        project_name = project_resource.scope_name || project_resource.project_id
        [ sort_order, project_name.downcase ]
      end
      @projects = Kaminari.paginate_array(projects).page(params[:page]).per(6)

      respond_to do |format|
        format.html 
        format.js
      end
 
    end

    def sync_now
      services.resource_management.sync_domain(@scoped_domain_id, with_projects: true)
      begin
        redirect_to :back
      rescue ActionController::RedirectBackError
        redirect_to admin_path()
      end
    end

    private

    def load_project_resource
      @project_resource = ResourceManagement::Resource.find(params.require(:id))
      raise ActiveRecord::RecordNotFound if @project_resource.domain_id != @scoped_domain_id or @project_resource.project_id.nil?
    end

    def load_domain_resource
      @resource = ResourceManagement::Resource.find(params.require(:id))
      raise ActiveRecord::RecordNotFound if @resource.domain_id != @scoped_domain_id or not @resource.project_id.nil?
    end

    def load_inquiry
      @inquiry = services.inquiry.get_inquiry(params[:inquiry_id])
      # Error Handling
      unless @inquiry
        render html: 'Could not find inquiry!'
        return
      end
      
      enforce_permissions("resource_management:admin_approve_request", {inquiry: {requester_uid: @inquiry.requester.uid}})

      # load additional data
      data = @inquiry.payload.symbolize_keys
      @project_resource = ResourceManagement::Resource.find(data[:resource_id])
      @project_name = services.identity.find_project(@project_resource.project_id).name
      @domain_resource = ResourceManagement::Resource.where(domain_id:@scoped_domain_id, project_id:nil, service:data[:service], name:data[:resource]).first
 
    end
 
    def prepare_data_for_resource_list(services, options={})
      # load resources for domain and projects within this domain
      resources = ResourceManagement::Resource.
        where(domain_id: @scoped_domain_id, service: services)

      domain_resources  = resources.where(project_id: nil).to_a
      project_resources = resources.where.not(project_id: nil)

      # check data age (see _data_age partial view)
      @min_updated_at, @max_updated_at = project_resources.pluck("MIN(updated_at), MAX(updated_at)").first

      # examine project quotas and usage
      stats = project_resources.
        group("service, name").
        pluck("service, name, MIN(current_quota), SUM(GREATEST(current_quota,0)), SUM(usage)")

      # prepare data for each resource for display
      @resource_status = Hash.new { |h,k| h[k] = [] }
      stats.each do |stat|
        service, name, min_current_quota, current_quota_sum, usage_sum = *stat
        has_infinite_current_quota = min_current_quota < 0

        # use existing domain resource, or create an empty mock object as a placeholder
        domain_resource = domain_resources.find { |q| q.service == service && q.name == name }
        domain_resource ||= ResourceManagement::Resource.new(
          service: service, name: name, approved_quota: -1,
        )

        # on overview, show only critical quotas
        is_critical = current_quota_sum > domain_resource.approved_quota or has_infinite_current_quota
        if options[:overview]
          next unless is_critical
        end

        # show warning in infobox when there are critical quotas
        @show_warning = true if is_critical
 
        @resource_status[service.to_sym] << {
          name:                       name,
          current_quota_sum:          current_quota_sum,
          usage_sum:                  usage_sum,
          has_infinite_current_quota: has_infinite_current_quota,
          domain_resource:            domain_resource,
        }
      end
    end

    # Some data collection that's shared between the details() and update() actions.
    def prepare_data_for_details_view(service, resource)
      # load domain resource and corresponding project resources
      resources = ResourceManagement::Resource.
        where(domain_id: @scoped_domain_id, service: service, name: resource)

      domain_resource   = resources.where(project_id: nil).first
      project_resources = resources.where.not(project_id: nil)

      # when no domain resource record exists yet, use an empty mock object
      domain_resource ||= ResourceManagement::Resource.new(
        domain_id: @scoped_domain_id, service: service, name: resource, approved_quota: 0,
      )

      # statistics over project resources
      min_current_quota, current_quota_sum, usage_sum = project_resources.
        pluck("MIN(current_quota), SUM(GREATEST(current_quota,0)), SUM(usage)").first

      @resource_status = {
        name:                       resource,
        current_quota_sum:          current_quota_sum,
        usage_sum:                  usage_sum,
        has_infinite_current_quota: min_current_quota < 0,
        domain_resource:            domain_resource,
      }

      return project_resources # this is used for further data collection by details()
    end

  end
end
