# alert_logic cookbook

This cookbook is available at [https://github.com/ryancragun/alert_logic-cookbook](https://github.com/ryancragun/alert_logic-cookbook)

This cookbook dowloads, installs, and configures a Server as an Alert Logic Threat Manager host node.

# Requirements

Requires a VM launched as a RightScale managed Server.

Please see the metadata.rb for current cookbook dependencies.  Currently `rightscale` is required for the `rightscale_marker` definition.

# Usage

Add recipe `alert_logic::install_threat_manager` to the nodes run_list along with the node[:alert_logic][:secret_key]` attribute.

# Attributes

`node[:alert_logic][:secret_key]`

# Recipes

`alert_logic::install_threat_manager`

# Author

Author:: Ryan Cragun (<ryan@rightscale.com>)
