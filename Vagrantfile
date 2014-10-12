# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'ipaddr'
require 'yaml'

def ip_addr(conf)
  IPAddr.new(conf['first_ip'])
end

CONF = YAML.load_file("nodes.yaml")
DEF_BOX = "centos65"
DEF_BOX_URL = "https://github.com/2creatives/vagrant-centos/releases/download/v6.5.1/centos65-x86_64-20131205.box"


if !File.directory?('.provision/conf/hieradata')
  Dir.mkdir('.provision/conf/hieradata')
end

# Write hosts.yaml -> the /etc/hosts module configuraiton
hosts = { 'hosts::hosts_hsh' => [] }
ip = ip_addr(CONF)
CONF['nodes'].each do |node|
  node['ip'] = ip = ip.succ()
  hosts['hosts::hosts_hsh'] << "#{node['ip']}    #{node['name']}.#{CONF['domain']} #{node['name']}"
end
File.open('.provision/conf/hieradata/hosts.yaml', 'w') do |os|
  YAML.dump(hosts, os)
end

# Write the common.yaml -> global node configuration info (zookeepers, namenode, etc)
common = {}
if CONF['service_mappings'] && CONF['service_mappings']['zookeeper']
  common['zookeeper::hosts'] = CONF['service_mappings']['zookeeper'].join(",")
  common['cdh4::accumulo14::accumulo_zookeepers'] = CONF['service_mappings']['zookeeper'].join(",")
  common['cdh4::hadoop_client::hadoop_namenode'] = CONF['service_mappings']['hadoop'].first
end
File.open('.provision/conf/hieradata/common.yaml', 'w') do |os|
  YAML.dump(common, os)
end

VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Iterate over the NODES array defining a new vm
  CONF['nodes'].each_with_index do | node, i|

    config.vm.define name(node) do |nc|

      nc.vm.hostname = "#{name(node)}.#{CONF['domain']}"

      nc.vm.network :private_network, ip: node['ip'].to_s
      nc.ssh.forward_agent = true

      nc.vm.box = box(node)
      nc.vm.box_url = box_url(node)

       nc.vm.provider :virtualbox do |vb|
         vb.customize ["modifyvm", :id, "--memory", "1536"]
       end

      # Required provisioners - puppet and the base puppet modules
      nc.vm.provision :shell do |shell|
        shell.path = ".provision/shell/puppet.sh"
        shell.args = ".provision/conf"
      end
      nc.vm.provision :puppet do |puppet|
        puppet.manifests_path = ".provision/manifests"
        puppet.module_path = ".provision/modules"
        puppet.manifest_file  = "default.pp"
        puppet.facter = facter_facts(i)
      end

      if with(node, 'pyenv')
        nc.vm.provision :shell, :path => '.provision/shell/pyenv.sh'
      end
      if with(node, 'mvn')
        nc.vm.synced_folder "~/.m2", "/home/vagrant/.m2"
        nc.vm.provision :shell, path: ".provision/shell/maven.sh"
      end

      if with_service(node, 'zookeeper')
       	#nc.vm.provision :shell, :path => '.provision/shell/zookeeper.sh'
       	nc.vm.provision :puppet do |puppet|
          puppet.manifests_path = ".provision/manifests"
          puppet.manifest_file = "zookeeper.pp"
          puppet.module_path = ".provision/modules"
          puppet.facter = facter_facts(i)
        end

      end
      if with_service(node, 'hadoop')
       	nc.vm.provision :puppet do |puppet|
          puppet.manifests_path = ".provision/manifests"
          puppet.manifest_file = "hadoop.pp"
          puppet.module_path = ".provision/modules"
          puppet.facter = facter_facts(i)
        end
      end
      if with_service(node, 'accumulo')
        nc.vm.provision :shell, :path => '.provision/shell/accumulo.sh'
      elsif with_service(node, 'accumulo14')
        nc.vm.provision :puppet do | puppet|
          puppet.manifests_path = ".provision/manifests"
          puppet.manifest_file = "accumulo.pp"
          puppet.module_path = ".provision/modules"
          puppet.facter = facter_facts(i)
        end
      end

    end
  end


end

def facter_facts(i)
  {
    :vagrant_id => i,
    :domain => CONF['domain'],
    :puppet_server => "#{CONF['nodes'][0]['name']}.#{CONF['domain']}",
  }
end

def name(node_def)
  node_def['name']
end

def box(node_def)
  node_def['box'] || DEF_BOX
end

def box_url(node_def)
  node_def['box_url'] || DEF_BOX_URL
end

# returns true if the node should be provisioned with the particular thing
def with(node, provisioner)
  if node['with']
    node['with'].include?(provisioner)
  end
end

# returns true if the service mappings indicate the node should have a particular service
def with_service(node, service)
  mapping = CONF['service_mappings']
  if mapping and mapping[service]
    mapping[service].include?(name(node))
  end
end
