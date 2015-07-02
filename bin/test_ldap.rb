#!/usr/bin/env ruby
# encoding: UTF-8

Encoding.default_external = Encoding::UTF_8

require 'bundler/setup'
require 'iniparse'
require 'helper_classes/dputs'
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
@field_id_ldap = :uidNumber

case 1
  when 0 # Read all entries
    dputs(3) { "Going to read #{@data_ldap_base}" }
    @data_ldap.search(:base => @data_ldap_base, :filter => filter) do |entry|
      dputs(4) { "DN: #{entry.dn}" }
    end
  when 1 # Write to one entry
    filter = Net::LDAP::Filter.eq('uid', 'ltest3')
    dn, uidnumber = 0, 0
    @data_ldap.search(:base => @data_ldap_base, :filter => filter) do |entry|
      dputs(3) { "DN: #{entry.dn} - uidn: #{entry.uidnumber} - entry: #{entry}" }
      dn = entry.dn
      uidnumber = entry.uidnumber.first
    end
    dp dn
    dp uidnumber
    value_stored = 'test'
    attribute = 'sn'
    dputs(3) { 'Replacing attribute in ' +
        "#{[@data_ldap_pass, dn, uidnumber, attribute, value_stored].inspect}" }

    if not dn
      dputs(0) { "Error: DN is empty... #{@dns.to_a.last(10).inspect}" }
      dputs(0) { "Error: DN is empty: id, field, value = #{id}, #{field}, #{value}" }
      #return
    end

    ret = @data_ldap.replace_attribute(dn, attribute, value_stored.to_s)
    #ret = @data_ldap.add_attribute(dn, attribute, value_stored.to_s)
    #ret = @data_ldap.replace_attribute(dn, 'objectClass', %w( inetOrgPerson posixAccount ))
    dp ret
    puts "Result: #{@data_ldap.get_operation_result.code}"
    puts "Message: #{@data_ldap.get_operation_result.message}"


    filter2 = Net::LDAP::Filter.eq(@field_id_ldap.to_s, uidnumber.to_s)
    @data_ldap.search(:base => @data_ldap_base,
                      :filter => filter2) do |entry|
      dputs(3) { "Found entry: #{entry.inspect}" }
      value_entry = entry[attribute][0].to_s
      value_entry.force_encoding(Encoding::UTF_8)
      if value_stored.to_s == value_entry
        dputs(0) { "returning value #{value_stored.inspect}" }
      else
        dputs(0) { "Error: Didn't get right return value: #{value_entry.inspect} instead of #{value_stored.inspect}" }
      end
    end
end
