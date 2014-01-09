#
# Cookbook Name:: alert_logic
# Provider:: threat_manager
#
# Copyright (C) 2014 Ryan Cragun
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
include AlertLogic::Helper

def whyrun_supported?
  true
end

action :install do
  if @current_resource.installed
    Chef::Log.info "#{new_resource} is already installed."
  else
    converge_by("Install #{new_resource}") do
      install_threat_manager
    end
  end
end

action :register do
  if @current_resource.registered
    Chef::Log.info "#{new_resource} is already registered."
  else
    converge_by("Register #{new_resource}") do
      register_threat_manager
    end
  end
end

action :remove do
  if @current_resource.installed
    converge_by("Remove #{new_resource}") do
      remove_threat_manager
    end
  else
    Chef::Log.info "#{@current_resource} is not installed."
  end
end

def load_current_resource
  @current_resource = Chef::Resource::AlertLogicThreatManager.new(new_resource.name)
  @current_resource.name(new_resource.name)
  @current_resource.secret_key(new_resource.secret_key)
  @current_resource.appliance_name(new_resource.appliance_name)
  @current_resource.installed   = ::File.exists?('/etc/init.d/al-threat-host')
  @current_resource.registered  = AlertLogic::Helper.host_is_registered?(
                                    new_resource.secret_key,
                                    new_resource.appliance_name,
                                    node[:ipaddress],
                                    node[:fqdn]
                                  )
  @current_resource
end

def remove_threat_manager
  log '   Uninstalling Alert Logic Threat Manager...'

  service 'al-threat-host' do
    action :disable
  end

  package 'al-threat-host' do
    action :remove
  end

  new_resource.updated_by_last_action(true)
end

def register_threat_manager
  log '   Registering node with Alert Logic appliance'

  secret_key = new_resource.secret_key
  fail 'ERROR: secret_key must be set' if secret_key == ''

  appliance_name = new_resource.appliance_name
  fail 'ERROR: appliance_name must be set' if appliance_name == ''

  ruby_block 'register-with-alert-logic-appliance' do
    block do
      AlertLogic::Helper.register_with_appliance(
        secret_key,
        appliance_name,
        node[:ipaddress],
        node[:fqdn]
      )
    end
  end

  new_resource.updated_by_last_action(true)
end

def install_threat_manager
  log '   Installing Alert Logic Threat Manager...'

  secret_key = new_resource.secret_key
  fail 'ERROR: secret_key must be set' if secret_key == ''

  download_base_href = 'https://scc.alertlogic.net/software/'
  package_name = value_for_platform(
    %w(centos redhat suse fedora) => {
      'default' => 'al-threat-host_LATEST.x86_64.rpm'
    },
    %w(ubuntu debian) => {
      'default' => 'al-threat-host_LATEST.amd64.deb'
    }
  )
  package_href = download_base_href + package_name
  package_file = "#{Chef::Config[:file_cache_path]}/#{package_name}"

  remote_file package_file do
    source package_href
    action :create_if_missing
    backup false
    not_if { ::File.exists?(package_file) }
  end

  package package_name do
    source package_file
    action :install
  end

  service 'al-threat-host' do
    action :enable
  end

  execute 'provision-host' do
    command   "/etc/init.d/al-threat-host provision --key #{secret_key} --inst-type host"
    action    :run
    notifies  :start, 'service[al-threat-host]', :immediately
    only_if   { ::File.exists?('/etc/init.d/al-threat-host') }
  end

  new_resource.updated_by_last_action(true)
end
