
require 'net/ldap'
require 'parseconfig'

#LDAP_FILE_CONF='/etc/ldapscripts/ldapscripts.conf'
#LDAP_FILE_CONF2='/etc/ldap.conf'
#LDAP_FILE_PASS='/etc/ldap.secret'
LDAP_FILE_CONF='ldapscripts.conf'
LDAP_FILE_PASS='ldap.secret'

class LDAP < StorageType
  attr_accessor :data_ldap_base, :data_ldap_users
  
  # Load the configuration file and set up different variables
  # for LDAP. This has to be loaded just once
  def configure( config )
    dputs( 2 ){ "Configuring LDAP: #{config.inspect}" }
    if config['ldap-config']
      @data_ldap_host, @data_ldap_base, @data_ldap_root, @data_ldap_users,
      @data_ldap_pass = config['ldap-config']
    else
      ldap_config = ParseConfig.new( LDAP_FILE_CONF )
      dputs( 2 ){ "Configuration options are #{ldap_config.get_params.inspect}" }
      @data_ldap_host, @data_ldap_base, @data_ldap_root, @data_ldap_users =
      ldap_config.params['SERVER'], ldap_config.params['SUFFIX'], ldap_config.params['BINDDN'],
      ldap_config.params['USUFFIX']
      @data_ldap_pass = `cat #{ LDAP_FILE_PASS }`
    end
    @data_ldap_users += ",#{@data_ldap_base}"
      %w( host base root pass users ).each{|v| eval( "dputs( 3 ){ @data_ldap_#{v}.to_s}" ) }
    
    @data_ldap = Net::LDAP.new :host => @data_ldap_host,
      :auth => {
        :method => :simple,
        :username => @data_ldap_root,
        :password => @data_ldap_pass
    }
    
    # Don't cache data, always ask
    @data_cache = false
    
    super config
    
    @dns = {}
  end
  
  def save(data)
    dputs( 2 ){ "Everything should already be saved..." }
  end
  
  def load
    data = {}
    # Read in the entries from the LDAP-directory
    dputs( 3 ){ "Reading LDAP-entries" }
    filter = Net::LDAP::Filter.eq( "cn", "*" )
    @field_id_ldap = @fields[ @data_field_id ][:ldap_name].to_sym
    
    dputs( 3 ){ "Going to read #{@data_ldap_base}" }
    @data_ldap.search( :base => @data_ldap_base, :filter => filter ) do |entry|
      #dputs( 4 ){ "DN: #{entry.dn}" }
      data_ldap = {}
      if entry.respond_to? @field_id_ldap
        field_id_value = entry[@field_id_ldap].to_s
        data_ldap = { @data_field_id => field_id_value }
        @fields.each{|k,v|
          ln = v[:ldap_name]
          if entry.respond_to? ln.to_sym
            value = entry[ln.to_sym][0].to_s
            #if entry.dn =~ /kaina/
            #  dputs( 0 ){ entry.inspect }
            #  dputs( 0 ){ data_ldap.inspect }
            #end
            # dputs( 4 ){ "Responding to #{[k,v,value,value.class].inspect}" }
            if value[0..0] == "["
              # dputs( 4 ){ "Parsing value #{value}" }
              value = JSON.parse( value )
            end
            data_ldap.merge!( { k => value } )
          end
        }
        # We hold a hash of all id_values to dn-entries for later use
        if entry.respond_to? :dn
          fiv = field_id_value.gsub(/[\[\]]/,'').to_i
          @dns[fiv] = entry[:dn][0]
          dputs( 4 ){ "Adding dn-entry #{entry[:dn][0]} with id #{fiv.inspect}" }
        end
      else
        dputs( 4 ){ "Field-id #{@field_id_ldap} not found. List of ids: #{entry.attribute_names.inspect}" }
      end
      # Often needed to check one entry...
      #if entry.dn =~ /mahamouth/
      #  dputs( 0 ){ entry.inspect }
      #  dputs( 0 ){ data_ldap.inspect }
      #end
      if data_ldap 
        data_ldap[@data_field_id] = data_ldap[@data_field_id].to_i
        data[ data_ldap[@data_field_id] ] = data_ldap
      end
    end
    dputs( 5 ){ data.inspect }
    return data
  end
  
  def check_login( uid, pass )
    ldap = Net::LDAP.new
    ldap.host = @data_ldap_host
    ldap.auth "uid=#{uid},#{@data_ldap_users}", pass
    dputs( 1 ){ ldap.inspect }
    return ldap.bind
  end
  
  # Searches for the field in the LDAP-entry, changes it and returns the new
  # value (which might not be what you expected).
  def set_entry( id, field, value )
    dputs( 3 ){ "Fields is #{@fields.inspect}" }
    attribute = @fields[field.to_sym][:ldap_name]
    if not attribute
      return value
    end
    dn = @dns[ id.to_i ]
    
    value_stored = value.class == Array ? value.to_json : value
    dputs( 3 ){ "Replacing attribute in " +
      "#{[ @data_ldap_pass, dn, attribute, field, value, value_stored ].inspect}" }

    if not dn
      dputs( 0 ){ "DN is empty... #{@dns.inspect}" }
      return
    end    
    
    ret = @data_ldap.replace_attribute( dn, attribute, value_stored )
    log_msg( 'DataElement', "Replaced #{attribute} in #{dn} with #{value}" )
    dputs( 3 ){ "State of LDAP is: #{@data_ldap.get_operation_result.message}" }
    @data_ldap.search( :base => @data_ldap_base, 
        :filter => Net::LDAP::Filter.eq( @field_id_ldap.to_s, id.to_s ) ) do |entry|
      dputs( 3 ){ "Found entry: #{entry.inspect}" }
      if value_stored.to_s == entry[attribute][0].to_s
        dputs( 4 ){ "returning value #{value.inspect}" }
        return value
      else
        dputs( 0 ){ "Didn't get right return value: #{entry[attribute[0]].to_s} instead of #{value.to_s}" }
      end
    end
    return nil
  end
  
  def get_entry( id, field )
    ret = nil
    attribute = @fields[field.to_sym][:ldap_name]
    filter = Net::LDAP::Filter.eq( @field_id_ldap.to_s, id.to_s )
    
    @data_ldap.search( :base => @data_ldap_base,
        :filter => filter ){ |entry|      
      dputs( 5 ){ "DN: #{entry.dn} - #{attribute}" }
      if entry.respond_to? attribute
        ret = entry[attribute][0]
        if ret.class == Net::BER::BerIdentifiedString and ret[0..0] == "["
          dputs( 4 ){ "Parsing value #{ret}" }
          ret = JSON.parse( ret )
        else
          ret = ret.to_s
          # Keep integers as integers
          if ret.to_i.to_s == ret
            ret = ret.to_i
          end
        end
      end
    }
    
    dputs( 5 ){ ret.inspect }
    return ret
  end

  # If our @entity has a "data_create"-method, it is called, and then the
  # object is extracted from the LDAP-tree.
  def data_create( data )
    if @entity.respond_to? :data_create
      dputs( 1 ){ "Going to call data_create of #{@name}" }
      @entity.data_create( data )
      uid = @fields.select{|k,v| v[:ldap_name].to_sym == :uid }[0][0]
      dputs( 1 ){ "Found uid to be field #{uid.inspect}: #{data[uid]}" }
      filter = Net::LDAP::Filter.eq( "uid", data[uid] )
      @field_id_ldap = @fields[ @data_field_id ][:ldap_name].to_sym
      
      dputs( 3 ){ "Going to read #{@data_ldap_base}" }
      @data_ldap.search( :base => @data_ldap_base, :filter => filter ) do |entry|
        dputs( 4 ){ "DN: #{entry.dn}" }
        if entry.respond_to? @field_id_ldap
					ldap_id = entry[@field_id_ldap].to_s.gsub( /[^0-9]/, '' )
          dputs( 2 ){ "Found #{@field_id_ldap}, getting real value of " +
						"#{ldap_id}"}
          id = ldap_id.to_i
          data[@data_field_id] = id
          @dns[id] = entry.dn.to_s
          dputs( 2 ){ "Found id=#{id} and dn=#{entry.dn.to_s}" }
        end
      end          
    else
      dputs( 0 ){ "LDAP can't create data on it's own! Needs #{@name}.data_create!" }
      exit 0
    end
    dputs( 0 ){ "Data is now #{data.inspect}" }
  end
end
