module ServiceLayer

  class ObjectStorageService < Core::ServiceLayer::Service

    def driver
      @driver ||= ObjectStorage::Driver::Fog.new({
        auth_url:   self.auth_url,
        region:     self.region,
        token:      self.token,
        domain_id:  self.domain_id,
        project_id: self.project_id,
      })
    end

    def available?(action_name_sym=nil)
      not current_user.service_url('object-store',region: region).nil?
    end

    def capabilities
      driver.list_capabilities
    end

    def account_exists?
      driver.account_exists?
    end

    def create_account
      driver.create_account
    end

    ##### containers

    def find_container(name)
      name.blank? ? nil : driver.map_to(ObjectStorage::Container).get_container(name)
    end

    def containers(filter={})
      driver.map_to(ObjectStorage::Container).containers(filter)
    end

    def new_container(attributes={})
      # maps to create_container in fog.rb
      ObjectStorage::Container.new(driver, attributes)
    end

    ##### objects

    def find_object(container_name, path)
      return nil if container_name.blank? or path.blank?
      return driver.map_to(ObjectStorage::Object).get_object(container_name, path)
    end

    def list_objects_at_path(container_name, path)
      return [] if container_name.blank?
      path = '' if path == '/' # treat container root correctly
      return driver.map_to(ObjectStorage::Object).objects_at_path(container_name, path)
    end

    # `contents` is expected to be an IO object. Wrap strings with `StringIO.new(the_string)`.
    def create_object(container_name, path, contents)
      driver.create_object(container_name, sanitize_path(path), contents)
      return
    end

    def create_folder(container_name, path)
      # a pseudo-folder is created by writing an empty object at its path, with
      # a "/" suffix to indicate the folder-ness
      driver.create_object(container_name, sanitize_path(path) + '/', StringIO.new(''))
    end

    def delete_folder(container_name, path)
      targets = driver.objects_below_path(container_name, sanitize_path(path) + '/').map do |obj|
        { container: container_name, object: obj['path'] }
      end
      driver.bulk_delete(targets)
    end

    ##### helpers

    def sanitize_path(path)
      # remove duplicate slashes that might have been created by naive path
      # joining (e.g. `foo + "/" + bar`)
      path = path.gsub(/^\/+/, '/')

      # remove leading and trailing slash
      return path.sub(/^\//, '').sub(/\/$/, '')
    end

  end
end
