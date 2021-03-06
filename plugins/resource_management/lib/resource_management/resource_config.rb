module ResourceManagement

  # This class describes a type of resource that this plugin can query.
  # The set of known ResourceConfigs is created in the all() class method.
  # Attributes include:
  #
  # - name          (Symbol):        the name of this resource (unique per service)
  # - service_name  (Symbol):        the name of the service that manages this resource
  # - service       (ServiceConfig): configuration for this service
  # - data_type     (DataType):      used for parsing and formatting quota/usage values for this resource

  class ResourceConfig
    attr_reader :name, :service_name, :data_type, :default_quota

    def initialize(service_name, name, options={})
      @name          = name.to_sym
      @service_name  = service_name.to_sym
      @data_type     = Core::DataType.new(options.fetch(:data_type, :number), options[:data_sub_type])
    end

    def service
      ResourceManagement::ServiceConfig.find(@service_name)
    end

    def self.all
      @all ||= [
        new(:compute,        :cores                     ),
        new(:compute,        :instances                 ),
        new(:compute,        :ram,                         data_type: :bytes, data_sub_type: :mega),
        # new(:compute,        :key_pairs                 ),
        # new(:compute,        :metadata_items            ),
        # new(:compute,        :server_groups             ),
        # new(:compute,        :server_group_members      ),
        # new(:compute,        :injected_files            ),
        # new(:compute,        :injected_file_content_bytes, data_type: :bytes),
        # new(:compute,        :injected_file_path_bytes,    data_type: :bytes),
        # new(:compute,        :fixed_ips                 ),
        new(:networking,     :floating_ips              ),
        new(:networking,     :networks                  ),
        new(:networking,     :subnets                   ),
        new(:networking,     :subnet_pools              ),
        new(:networking,     :ports                     ),
        new(:networking,     :routers                   ),
        new(:networking,     :security_groups           ),
        new(:networking,     :security_group_rules      ),
        new(:networking,     :rbac_policies             ),
        new(:dns,            :zones                     ),
        new(:dns,            :recordsets                ),
        new(:dns,            :records                   ),
        new(:block_storage,  :capacity,                    data_type: :bytes, data_sub_type: :giga),
        new(:block_storage,  :snapshots                 ),
        new(:block_storage,  :volumes                   ),
        new(:object_storage, :capacity,                    data_type: :bytes),
        # :mock_service can be enabled with ResourceManagement::ServiceConfig.mock!
        new(:mock_service,   :things                    ),
        new(:mock_service,   :capacity,                    data_type: :bytes),
        new(:loadbalancing,  :loadbalancers             ),
        new(:loadbalancing,  :listeners                 ),
        new(:loadbalancing,  :pools                     ),
        new(:loadbalancing,  :healthmonitors            ),
        new(:loadbalancing,  :l7policies                )
      ]

      # only show resources for enabled services
      enabled_services = ServiceConfig.all.map(&:name)
      return @all.select { |res| enabled_services.include?(res.service_name) }
    end

  end

end
