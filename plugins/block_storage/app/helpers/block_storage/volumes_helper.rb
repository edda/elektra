module BlockStorage
  module VolumesHelper
    def get_attachments(volume, servers)
      attachments = []
      if volume.status == 'in-use'
        volume.attachments.each do |att|
          servers = services.compute.servers() unless servers
          server_id = att['server_id'] || att['serverId']
          server = servers.find { |s| s.id == server_id }
          attachments << { device: att['device'], server_id: server_id, server_name: server ? server.name : nil }
        end
      end
      return attachments
    end
  end
end
