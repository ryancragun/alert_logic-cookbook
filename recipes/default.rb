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

file_cache = ::File.join(::File.dirname(__FILE__), '..', 'files', 'default')
version = '0.1.1'
pkg = "alert_logic-#{version}.gem"

chef_gem "#{file_cache}/#{pkg}" do
  action :install
end

Gem.clear_paths
require 'alert_logic'
