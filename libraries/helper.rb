module AlertLogic
  # Module methods for easy use in providers
  module Helper
    # TODO: Support registering via FQDN and IP
    def self.register_with_appliance(key, appliance, ip, fqdn)
      AlertLogic.secret_key = key
      tries ||= 3
      host = AlertLogic::ProtectedHost.find('metadata.local_ipv4' => ip)[0]
      host.assign_appliance(appliance)
    rescue => e
      Chef::Log.info "Error: #{e.message}, retrying..."
      sleep(60) && retry unless (tries -= 1).zero?
    end

    def self.host_is_registered?(key, appliance, ip, fqdn)
      AlertLogic.secret_key = key
      appliance = AlertLogic::Appliance.find('name' => appliance).first
      host = AlertLogic::ProtectedHost.find('metadata.local_ipv4' => ip)[0]
      host.appliance?(appliance)
    rescue => e
      Chef::Log.info "Error:  #{e.message}"
      false
    end
  end
end
