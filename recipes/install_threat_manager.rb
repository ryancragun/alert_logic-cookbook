#
# Cookbook Name:: alert_logic
# Recipe:: default
#
# Copyright (C) 2013 Ryan Cragun
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

rightscale_marker

log "   Installing Alert Logic Threat Manager..."

download_base_href = "https://scc.alertlogic.net/software/"
package_name = value_for_platform(
  ["centos", "redhat", "suse", "fedora"] => {
    "default" => "al-threat-host_LATEST.x86_64.rpm"
  },
  ["ubuntu", "debian"] => {
    "default" => "al-threat-host_LATEST.amd64.deb"
  }
)

package_href = download_base_href + package_name
package_location = "#{Chef::Config[:file_cache_path]}/#{package_name}"

remote_file package_location do
  source package_href
  action :create_if_missing
  backup false
end

package package_name do
  source package_location
  action :install
end

service "al-threat-host" do 
  action :enable
end

execute "provision host" do
  command "/etc/init.d/al-threat-host provision --key #{node[:alert_logic][:secret_key]} --inst-type host"
  action :run
  notifies :start, "service[al-threat-host]"
  only_if { ::File.exists?("/etc/init.d/al-threat-host") }
end

log "   Threat Manager installation completed."
