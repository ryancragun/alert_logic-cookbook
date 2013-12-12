require 'rest_client'
require 'json'

module AlertLogic
  
  module Helper
    def self.register_with_appliance(node)
      AlertLogic::ApiUtil.new(node).register_with_appliance
    end
  end
  
  class ApiUtil
    attr_accessor :node, :api
    
    def initialize(node)
      @node = node
      @api = create_api_resource
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
        message << @node[:alert_logic][:appliance_name]
        raise message
      end
    end

    def create_api_resource
      root_resource = 'https://publicapi.alertlogic.net/api/tm/v1/'
      RestClient::Resource.new(
        root_resource, 
        { :user => @node[:alert_logic][:secret_key], 
          :headers => { :accept => :json }
        }
      )
    end

    def parse_api_response(api_call)
      if api_call.code.to_s =~ /^2\d{2}$/
        JSON.parse(api_call)
      else
        raise "Error Making API Call: #{api_call.net_http_res}"
      end
    rescue Exception => e
      raise "Error with API Call: #{e.message} #{e.response} #{api_call}"
    end

    def do_get(resource, params={})
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
        'name' => @node[:alert_logic][:appliance_name]
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
        'metadata.local_ipv4' => @node[:ipaddress]
      }
      do_get('protectedhost', params)
    end

    def get_protected_host_by_fqdn
      hosts = do_get('protectedhost')
      hosts.select do |host|
        host['protectedhost']['metadata']['local_hostname'] == @node[:fqdn] &&
        host['protectedhost']['metadata']['local_ipv4'].any? do |ip| 
          ip == @node[:ipaddress]
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
    end
    
    def have_ip_match?(a, b)
      (a & b).empty? ? false : true
    end
    
    def pluralize(string)
      string =~ /^\w+y$/ ? string.gsub('y', 'ies') : "#{string}s"
    end

    def host_is_registered?
      appliance_id = get_appliance['appliance']['id']
      assigned_id = if !get_protected_host['protectedhost']['appliance'].nil?
        get_protected_host['protectedhost']['appliance']['assigned_to']
      else
        nil
      end

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
        "protectedhost" => {
          "appliance" => {
            "policy" => { "id" => appliance_policy_id }
          }
        }
      }
      res = do_post('protectedhost', host_id, content.to_json)
      Chef::Log.info 'Successfully registered host!' unless res.nil? || res.empty?
    end
  end
end
