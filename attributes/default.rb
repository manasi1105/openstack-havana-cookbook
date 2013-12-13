require "socket"
require 'securerandom'

external_ip  = UDPSocket.open {|s| s.connect("8.8.8.8", 1); s.addr.last}

iface = Mixlib::ShellOut.new("ip a | awk '/#{external_ip}/ { print $7 }'")
iface.run_command
iface.error!
external_iface = iface.stdout[0..-2]

vg = Mixlib::ShellOut.new("vgs --sort -size --rows | grep VG -m 1 | awk '{print $2}'")
vg.run_command
vg.error!
largest_vg  = vg.stdout[0..-2]

default[:creds][:admin_password]  = "cl0udAdmin"
default[:creds][:mysql_password]  = "cl0udAdmin"
default[:creds][:keystone_token]  = SecureRandom.urlsafe_base64(20)
default[:creds][:swift_hash]      = SecureRandom.urlsafe_base64(20)
default[:creds][:neutron_secret]  = SecureRandom.urlsafe_base64(20)
default[:creds][:ssh_keypair]     = "openstack"

default[:ip][:controller]   = node[:ipaddress]
default[:ip][:qpid]         = node[:ip][:controller]
default[:ip][:keystone]     = node[:ip][:controller]
default[:ip][:swift]        = node[:ip][:controller]
default[:ip][:glance]       = node[:ip][:controller]
default[:ip][:cinder]       = node[:ip][:controller]
default[:ip][:neutron]      = node[:ip][:controller]
default[:ip][:nova]         = node[:ip][:controller]
default[:ip][:heat]         = node[:ip][:controller]
default[:ip][:ceilometer]   = node[:ip][:controller]
default[:ip][:monitoring]   = node[:ip][:controller]

default[:vmware][:driver]     = "esxi"
default[:vmware][:host]       = "192.168.250.21"
default[:vmware][:user]       = "root"
default[:vmware][:password]   = "vBh!3dFv"
default[:vmware][:wsdl_loc]   = "https://#{node[:vmware][:host]}/sdk/vimService.wsdl"
default[:vmware][:port_group] = "VM Network"

default[:auto][:volume_driver] = case node[:vmware][:driver]
when "esxi"
  "cinder.volume.drivers.vmware.vmdk.VMwareEsxVmdkDriver"
else
  "cinder.volume.drivers.vmware.vmdk.VMwareVcVmdkDriver"
end

default[:auto][:compute_driver] = case node[:vmware][:driver]
when "esxi"
  "vmwareapi.VMwareESXDriver"
else
  "vmwareapi.VMwareVCDriver"
end

default[:auto][:volume_group] = largest_vg
default[:auto][:external_ip] = external_ip
default[:auto][:external_nic] = external_iface
default[:auto][:gateway] = node[:network][:default_gateway]
default[:auto][:netmask] = node[:network][:interfaces][external_iface]\
[:addresses][external_ip][:netmask]

