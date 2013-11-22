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

default[:creds][:admin_password]  = SecureRandom.urlsafe_base64(8)
default[:creds][:mysql_password]  = SecureRandom.urlsafe_base64(8)
default[:creds][:keystone_token]  = SecureRandom.urlsafe_base64(20)
default[:creds][:swift_hash]      = SecureRandom.urlsafe_base64(20)
default[:creds][:neutron_secret]  = SecureRandom.urlsafe_base64(20)
default[:creds][:ssh_keypair]     = "openstack"
default[:creds][:esxi_password]   = "mySuperSecret"

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
default[:ip][:esxi]         = "192.168.250.100"

default[:auto][:volume_group] = largest_vg
default[:auto][:external_ip] = external_ip
default[:auto][:external_nic] = external_iface
default[:auto][:gateway] = node[:network][:default_gateway]
default[:auto][:netmask] = node[:network][:interfaces][external_iface]\
[:addresses][external_ip][:netmask]

