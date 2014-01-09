require 'rest_client'
require 'json'

module AlertLogic
  # Module methods for easy use in providers
  module Helper
    def self.register_with_appliance(key, appliance, ip, fqdn)
      AlertLogic::ApiUtil.new(key, appliance, ip, fqdn).register_with_appliance
    end

    def self.host_is_registered?(key, appliance, ip, fqdn)
      AlertLogic::ApiUtil.new(key, appliance, ip, fqdn).host_is_registered?
    end
  end

  # Prototype ApiUtil class to handle the Alert Logic API.
  # TODO: Break this class down and refactor with proper exception handling and
  #       and define common interfaces.
  class ApiUtil
    attr_accessor :ip, :fqdn, :api, :secret_key, :appliance_name

    def initialize(secret_key, appliance_name, ip, fqdn)
      @secret_key     = secret_key
      @appliance_name = appliance_name
      @ip             = ip
      @fqdn           = fqdn
      @api            = create_api_resource
    end

    def register_with_appliance
      if appliance_is_running?
        if host_is_registered?
          Chef::Log.info 'The host is already registered to the proper appliance!'
          true
        else
          register_host
        end
      else
        message = 'Could not find an operational appliance with name: '
        message << @appliance_name
        fail message
      end
    end

    def create_api_resource
      root_resource = 'https://publicapi.alertlogic.net/api/tm/v1/'
      RestClient::Resource.new(
        root_resource,
        :user => @secret_key,
        :headers => { :accept => :json }
      )
    end

    def parse_api_response(api_call)
      if api_call.code.to_s =~ /^2\d{2}$/
        JSON.parse(api_call)
      else
        fail "Error Making API Call: #{api_call.net_http_res}"
      end
    rescue RestClient::RequestFailed => e
      raise "Error with API Call: #{e.message} #{e.response} #{api_call}"
    end

    def do_get(resource, params = {})
      parse_api_response(
        @api[pluralize(resource)].get(:params => params)
      )[pluralize(resource)]
    end

    def do_post(resource, resource_id, content)
      parse_api_response(
        @api["#{pluralize(resource)}/#{resource_id}"].post(
          content,
          :content_type => 'application/json'
        )
      )
    end

    def appliance_is_running?
      get_appliance ? true : false
    end

    def get_appliance
      params = {
        'status.status' => 'ok',
        'name' => @appliance_name
      }
      do_get('appliance', params).first
    end

    def get_protected_host
      res = get_protected_host_by_ip
      if res.empty?
        fallback = get_protected_host_by_fqdn
        fallback.empty? ? {} : fallback.first
      else
        res.first
      end
    end

    def get_protected_host_by_ip
      params = {
        'status.status' => 'ok',
        'metadata.local_ipv4' => @ip
      }
      do_get('protectedhost', params)
    end

    def get_protected_host_by_fqdn
      hosts = do_get('protectedhost')
      hosts.select do |host|
        host['protectedhost']['metadata']['local_hostname'] == @fqdn &&
        host['protectedhost']['metadata']['local_ipv4'].any? do |ip|
          ip == @ip
        end
      end
    end

    def get_appliance_assignment_policy(appliance_id)
      params = {
        'type' => 'appliance_assignment',
        'appliance_assignment.appliances' => appliance_id
      }
      do_get('policy', params).first
    end

    def get_assigned_hosts(appliance_id)
      params = { 'appliance.assigned_to' => appliance_id }
      do_get('protectedhost', params)
    end

    def get_resource_ips(resource_type, resources)
      resources = [resources] if resources.is_a?(Hash)
      resources.map do |resource|
        ( resource[resource_type]['metadata']['public_ipv4'] +
          resource[resource_type]['metadata']['local_ipv4']
        ).flatten
      end.flatten # no #flat_map in Ruby 1.8
    rescue
      []
    end

    def have_ip_match?(a, b)
      (a & b).empty? ? false : true
    end

    def pluralize(string)
      string =~ /^\w+y$/ ? string.gsub('y', 'ies') : "#{string}s"
    end

    def get_host_assigned_id
      host = get_protected_host
      return nil if host.empty?
      host['appliance']['id']['assigned_to']
    rescue
      nil
    end

    def host_is_registered?
      appliance_id = get_appliance['appliance']['id']
      assigned_id = get_host_assigned_id

      if appliance_id == assigned_id
        true
      else
        assigned_hosts = get_assigned_hosts(appliance_id)
        assigned_hosts_ips = get_resource_ips('protectedhost', assigned_hosts)
        host_ips = get_resource_ips('protectedhost', get_protected_host)
        have_ip_match?(assigned_hosts_ips, host_ips)
      end
    end

    def register_host
      appliance_id = get_appliance['appliance']['id']
      appliance_policy_id = get_appliance_assignment_policy(appliance_id)['policy']['id']
      host_id = get_protected_host['protectedhost']['id']
      content = {
        'protectedhost' => {
          'appliance' => {
            'policy' => { 'id' => appliance_policy_id }
          }
        }
      }
      res = do_post('protectedhost', host_id, content.to_json)
      Chef::Log.info 'Successfully registered host!' unless res.nil? || res.empty?
    end
  end
end
