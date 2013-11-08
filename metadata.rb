name             'centos_cloud'
maintainer       'cloudtechlab'
maintainer_email 'laboshinl@gmail.com'
license          'All rights reserved'
description      'Installs/Configures openstack cloudstructure based on CentOS 6.4'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.2.1'
%w{ simple_iptables libcloud selinux tar}.each do |depend|
  depends depend
end
supports "centos"
