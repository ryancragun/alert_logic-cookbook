name             'alert_logic'
maintainer       'Ryan Cragun'
maintainer_email 'ryan@rightscale.com'
license          'Apache 2.0'
description      'Installs/Configures alert_logic'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

%w(redhat ubuntu centos debian fedora suse).each { |distro| supports distro }

depends "rightscale"

recipe "alert_logic::install_threat_manager", "Installs Alert Logic Threat Manager"

attribute "alert_logic/secret_key", 
  :display_name => "Alert Logic Secret Key",
  :description => "The Secret Key required to provision Alert Logic Threat Manager",
  :default => "",
  :required => "required",
  :recipes => ["alert_logic::install_threat_manager"]
