#!/usr/bin/env ruby
require 'optparse'
require 'fileutils'

CONTENTS = <<-EOS
Listen %{port} https
<VirtualHost *:%{port}>
  ProxyPass / https://%{ip_address}/
  <Location />
    ProxyPassReverse https://%{ip_address}/
  </Location>
  SSLEngine on
  SSLCertificateFile /etc/pki/tls/certs/localhost.crt
  SSLCertificateKeyFile /etc/pki/tls/private/localhost.key
  ProxyPreserveHost on
  SSLVerifyClient none
  SSLProxyEngine On
  SSLOptions +StdEnvVars +ExportCertData +FakeBasicAuth
  SSLProxyVerify none
  SSLProxyCheckPeerCN off
  SSLProxyCheckPeerName off
  SSLProxyCheckPeerExpire off
</VirtualHost>
EOS

PROXY_CONF="IncludeOptional conf.d/virt_hosts/%{range}/*.conf"

def make_virt_hosts(options)
  base = options[:base]
  range = options[:range]
  config_dir = options[:config_dir]
  virt_hosts_base_dir = File.join(config_dir, "virt_hosts", range)
  virt_hosts_file = File.join(config_dir, "virt-hosts-#{range}.conf")

  File.open(virt_hosts_file, 'w') { |file| file.write(PROXY_CONF % {:range => range} ) }

  FileUtils::mkdir_p virt_hosts_base_dir

  255.times do |count|
    filename = File.join(virt_hosts_base_dir, "#{count}.conf")
    ip_address = "#{range}.#{count}"
    file_contents = CONTENTS % {:ip_address => ip_address, :port => (base + count)}
    File.open(filename, 'w') { |file| file.write(file_contents) }
  end
end

options = {:base => 50000, :range => "192.168.121", :config_dir => "/etc/httpd/conf.d"}

opt_parser = OptionParser.new do |opt|
    opt.on("-p","--port PORT", Numeric, "which  base port to append, default: #{options[:base]}") do |base|
    options[:base] = base
  end

  opt.on("-r","--range IP_RANGE", "ip range to generate on, default: #{options[:range]}") do |range|
    options[:range] = range
  end

  opt.on("-d","--dir ConfigDir", "conf.d directory default => #{options[:config_dir]}") do |config_dir|
    options[:config_dir] = config_dir
  end


  opt.on("-h","--help","help") do
    puts opt_parser
    exit
  end
end

opt_parser.parse!
make_virt_hosts(options)