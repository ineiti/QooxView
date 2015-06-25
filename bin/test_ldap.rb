require 'bundler/setup'
require 'iniparse'
require 'helperclasses'

include HelperClasses::DPuts

DEBUG_LVL=3

dputs(2) { "Configuring LDAP: #{config.inspect}" }
file_conf = '/etc/ldapscripts/ldapscripts.conf'
ldap_config = IniParse.parse(File.read(file_conf))
dputs(2) { "Configuration options are #{ldap_config.get_params.inspect}" }
@data_ldap_host, @data_ldap_base, @data_ldap_root, @data_ldap_users =
    ldap_config['SERVER'], ldap_config['SUFFIX'], ldap_config['BINDDN'],
        ldap_config['USUFFIX']

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
@field_id_ldap = @fields[@data_field_id][:ldap_name].to_sym

dputs(3) { "Going to read #{@data_ldap_base}" }
@data_ldap.search(:base => @data_ldap_base, :filter => filter) do |entry|
  dputs(4) { "DN: #{entry.dn}" }
end
