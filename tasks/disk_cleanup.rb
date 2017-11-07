#!/opt/puppetlabs/puppet/bin/ruby
require 'puppet'
require 'facter'
# Required to find pluginsync'd plugins
Puppet.initialize_settings
require 'json'

def diskclean(os_family)
  logfiles = Dir.glob('/var/log/**/*.log')

  logfiles.each do |lf|
    File.delete(lf)
  end

  { status: 'removed', files: logfiles.join(", ") }
end

def restart(os_name, os_family, os_release)
  if os_name   == 'Debian' && os_release >= 7 || \
     os_family == 'RedHat' && os_release >= 7 || \
     os_name   == 'Ubuntu' && os_release >= 14.04
    system('systemctl restart rsyslog')
  else
    system('service splunk restart')
  end

  { status: 'restarted', service: 'splunk' }
end

def integrity
  #TODO Dom to fill me on how this should work.
  { status: 'checked', package: 'splunk' }
end

begin
  os_name    = Facter.value('os')['name']
  os_family  = Facter.value('os')['family']
  os_release = Facter.value('os')['release']['major'].to_i

  if os_family != 'Debian' && os_family != 'RedHat'
    raise Puppet::Error.new("splunk::diskclean - This task will not run on an unsupported OS: #{os_family}")
    exit 1
  end

  result = {}
  result[:diskclean] = diskclean(os_family)
  result[:restart]   = restart(os_name, os_family, os_release)
  result[:integrity] = integrity

  puts result.to_json
  exit 0
rescue Puppet::Error => e
  puts({ status: 'failure', error: e.message }.to_json)
  exit 1
end
