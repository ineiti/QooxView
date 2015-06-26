#!/usr/bin/env ruby
# encoding: UTF-8

Encoding.default_external = Encoding::UTF_8

require 'bundler/setup'
require 'iniparse'
require 'helper_classes'
require 'net/ldap'

include HelperClasses::DPuts

DEBUG_LVL=4

def get_param(lc, param)
  lc['__anonymous__'][param].delete('"\'')
end

file_conf = '/etc/ldapscripts/ldapscripts.conf'
ldap_config = IniParse.parse(File.read(file_conf))
dputs(2) { "Configuration options are #{ldap_config.to_hash.inspect}" }
@data_ldap_host, @data_ldap_base, @data_ldap_root, @data_ldap_users =
    get_param(ldap_config, 'SERVER'), get_param(ldap_config, 'SUFFIX'),
        get_param(ldap_config, 'BINDDN'), get_param(ldap_config, 'USUFFIX')

file_pass = '/etc/ldap.secret'
@data_ldap_pass = `cat #{ file_pass }`
@data_ldap_users += ",#{@data_ldap_base}"
%w( host base root pass users ).each { |v| eval("dputs( 3 ){ @data_ldap_#{v}.to_s}") }

@data_ldap = Net::LDAP.new :host => @data_ldap_host,
                           :auth => {
                               :method => :simple,
                               :username => @data_ldap_root,
                               :password => @data_ldap_pass
                           }

# Read in the entries from the LDAP-directory
dputs(3) { 'Reading LDAP-entries' }
filter = Net::LDAP::Filter.eq('cn', '*')
@field_id_ldap = :uid

dputs(3) { "Going to read #{@data_ldap_base}" }
@data_ldap.search(:base => @data_ldap_base, :filter => filter) do |entry|
  dputs(4) { "DN: #{entry.dn}" }
end
