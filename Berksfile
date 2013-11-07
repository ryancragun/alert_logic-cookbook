site :opscode

group :integration do
  cookbook 'rightscaleshim', github: 'rgeyer-rs-cookbooks/rightscaleshim'
  cookbook 'rightscale', github: 'rightscale/rightscale_cookbooks',
    branch: 'release13.05', rel: 'cookbooks/rightscale'
  cookbook 'sys', github: 'rightscale/rightscale_cookbooks',
            branch: 'release13.05', rel: 'cookbooks/sys'
  cookbook 'sys_firewall', github: 'rightscale/rightscale_cookbooks',
            branch: 'release13.05', rel: 'cookbooks/sys_firewall'
  cookbook 'driveclient', github: 'racker/managed-cloud-driveclient'
  cookbook 'cloudmonitoring', github: 'racker/cookbook-cloudmonitoring'
end

metadata
