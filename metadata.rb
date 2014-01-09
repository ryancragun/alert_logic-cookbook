name             'alert_logic'
maintainer       'Ryan Cragun'
maintainer_email 'ryan@rightscale.com'
license          'Apache 2.0'
description      'Installs/Configures alert_logic'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.2.0'

%w(redhat ubuntu centos debian fedora suse).each { |distro| supports distro }

depends 'rightscale'

recipe 'alert_logic::install_threat_manager',
  'Installs Alert Logic Threat Manager'

attribute 'alert_logic/secret_key',
  :display_name => 'Alert Logic Secret Key',
  :description  => 'The 50 character Alert Logic API Secret Key',
  :required     => 'required',
  :recipes      => ['alert_logic::install_threat_manager']

attribute 'alert_logic/appliance_name',
  :display_name => 'Alert Logic Appliance Name',
  :description =>
    'The Name of the Alert Logic appliance that you wish to register the' +
    ' Server with. On AWS this is commonly the AWS ID of the running' +
    ' Appliance, eg: i-34eb453',
  :required => 'required',
  :recipes => ['alert_logic::install_threat_manager']
