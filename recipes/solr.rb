
node.override['java']['install_flavor'] = 'oracle'
node.override['java']['jdk_version'] = '7'
node.override['java']['oracle']['accept_oracle_download_terms'] = true

node.override['tomcat']['port'] = 8983

include_recipe 'tomcat'

version_hash = {
  '4.2.0' => '6929d06fafea1a8b1a3e2dcee0ca4afd93db7dd9333468977aa4347da01db7ed',
  '4.2.1' => '648a4b2509f6bcac83554ca5958cf607474e81f34e6ed3a0bc932ea7fac40b99',
  '4.3.0' => 'b28240167ce6dd6a957c548ea6085486a4d27a02a643c4812a6d4528778ea9b7',
  '4.3.1' => '99c27527122fdc0d6eba83ced9598bf5cd3584954188b32cb2f655f1e810886b',
  '4.4.0' => 'f188313f89ac53229d0b89e35391facd18774e6f708803151e50ba61bbe18906',
  '4.5.0' => '8f53f9a317cbb2f0c8304ecf32aa3b8c9a11b5947270ba8d1d6372764d46f781',
  '4.5.1' => '8726fa10c6b92aa1d2235768092ee2d4cd486eea1738695f91b33c3fd8bc4bd7',
  '4.6.0' => '2a4a6559665363236653bec749f580a5da973e1088227ceb1fca87802bd06a3f'
}

node.default['solr']['solr_directory'] = '/var/solr'
node.default['solr']['solr_version'] = '4.2.1'


remote_file "#{Chef::Config[:file_cache_path]}/solr.tgz" do
  owner "root"
  group "root"
  mode "0644"
  source "http://archive.apache.org/dist/lucene/solr/#{node['solr']['solr_version']}/solr-#{node['solr']['solr_version']}.tgz" 
  checksum "#{version_hash[node['solr']['solr_version']]}"
  action :create
end

directory node['solr']['solr_directory'] do
    owner "tomcat6"
    group "tomcat6"
    mode "0755"
    action :create
end

bash 'extract_solr_package' do
  cwd ::File.dirname("#{Chef::Config[:file_cache_path]}/solr.tgz")
  code <<-EOH
    mkdir -p /tmp/solr
    tar xzf #{Chef::Config[:file_cache_path]}/solr.tgz -C /tmp/solr
    cp -a /tmp/solr/solr-#{node['solr']['solr_version']}/example/solr/. #{node['solr']['solr_directory']}
    cp /tmp/solr/solr-#{node['solr']['solr_version']}/dist/solr-#{node['solr']['solr_version']}.war #{node['solr']['solr_directory']}/solr.war
  EOH
  not_if { ::File.exists?("#{node['solr']['solr_directory']}/solr.war") }
end

bash "copy_external_dependencies" do
  cwd ::File.dirname('/tmp/solr.tgz')
  code <<-EOH
    cp -a /tmp/solr/solr-#{node['solr']['solr_version']}/example/lib/ext/* /usr/share/tomcat6/lib/
  EOH
  only_if { ::File.exists?("/tmp/solr/solr-#{node['solr']['solr_version']}/example/lib/ext") }
end

bash "set_ownership" do
  cwd "/tmp"
  code <<-EOH
    chown -R tomcat6:tomcat6 #{node['solr']['solr_directory']}
  EOH
end

template "/etc/tomcat6/Catalina/localhost/solr.xml" do
    source "solr.xml.erb"
    owner "tomcat6"
    group "tomcat6"
    mode "0644"
    variables({
      'solr_install_directory' => node['solr']['solr_directory']
      })
end

