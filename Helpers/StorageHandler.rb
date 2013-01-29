=begin
Holds all DataTypes for an entity
=end

module StorageHandler
  # Checks whether there is a configuration-option which wants to replace
  # the StorageType
  def replace_st( st )
    if $config[:StorageHandler]
      conf = $config[:StorageHandler]
      if conf[:Replace]
        conf[:Replace].each{|k,v|
          if st.to_sym == k.to_sym
            dputs( 2 ){ "Replacing #{k.inspect} with #{v.inspect}" }
            st = v.to_sym
          end
        }
      end
    end
    st.to_sym
  end

  # Adds a new value to the storages to hold the appropriate values.
  def add_value_to_storage( value )
    return if ! value.st
    args = value.args.merge( :dtype => value.dtype )
    if value.st != "ALL"
      st = replace_st( value.st )
      if not @storage.has_key? st
        # A request for another type
        add_new_storage( st )
      end
      @storage[st].add_field( value.name, args )
    else
      @storage.each{|k,v|
        v.add_field( value.name, args )
      }
    end
  end

  def field_args( name )
    @storage.each{|k,v|
      if v.has_field name
        return v.field_args name
      end
    }
    nil
  end

  # Adds a new storage type - returns the new created or already initialised storage-type
  def add_new_storage( st, config = {} )
    st = replace_st( st )

    if ! StorageType.has? st
      dputs( 0 ){ "Can't find StorageType of -#{st.inspect}-" }
      exit 1
    end

    if has_storage? st
      dputs( 3 ){ "Storage-type -#{st}- already exists" }
    else
      dputs( 3 ){ "Adding storage-type -#{st}-" }
      @storage[ st ] = StorageType.new_st( st, self, config )
      dputs( 3 ){ "@storage is #{@storage.inspect}" }
    end

    @storage[st]
  end

  def has_storage?( st )
    @storage ? ( @storage.has_key? st.to_sym ) : false
  end

  def has_field?(f)
    @storage.each{|k,v|
      if v.has_field f
        return true
      end
    }
    return false
  end

  # Have a handler for the ActiveRecord-type find_by_ and the name
  # of the field to search for
  def find_key_by( field, value )
    #dputs( 5 ){ "( #{field}, #{value} ) with #{@data.inspect}" }
    @data.each_key{|k|
      # dputs( 5 ){ "Searching :#{value}: in #{field} of #{k} which is :#{@data[k][field.to_sym]}:" }
      if @data[k] and @data[k][field.to_sym].to_s.downcase == value.to_s.downcase
        return k
      end
    }
    return nil
  end
 
  def find( field, value )
    result = find_by( field, value )
    return result ? result.data : nil
  end

  def find_by( field, value )
    key = find_key_by( field, value )
    return key ? get_data_instance( key ) : nil
  end

  def search_all
    search_by( @data_field_id, ".*" )
  end

  # Similar to find_by, but searches multiple instances that are similar to the
  # value, returns the instances
  def search_by( field, value )
    result = []
    field = field.to_sym
    @data.each_key{|k|
      #dputs( 5 ){ "Searching :#{value}: in #{field} of #{k} which is :#{@data[k][field.to_sym]}:" }
      if @data[k]
        [@data[k][field]].flatten.each{|d|
          if d.to_s =~ /#{value.to_s}/i
            dputs( 4 ){ "Found data-entry #{k}: #{@data[k].inspect}" }
            result.push get_data_instance( k )
          end
        }
      end
    }
    return result
  end

  # Like search_by, but only ONE exact matche
  def match_by( field, value )
    ret = search_by( field, "^#{value}$" )
    if ret.length > 0
      return ret[0]
    else
      return nil
    end
  end
  
  # Like search_by, but only exact matcheS
  def matches_by( field, value )
    ret = search_by( field, "^#{value}$" )
    return ret
=begin
    if ret.length > 0
      return ret
    else
      return []
    end
=end
  end
  
  # filter is a hash with field/value-pairs to be searched.
  def filter_by( filter )
    keys = filter.keys
    key = keys.shift
    res = search_by( key, filter[key] ).collect{|r| r.data}
    # Refine the search
    keys.each{|k|
      res = res.select{|r|
        dputs( 5 ){ "Searching results for #{[r, k, filter[k]].inspect}" }
        r.has_key? k and r[k].to_s =~ /#{filter[k].to_s}/i
      }
    }
    res
  end

  def new_id
    last_id = 1
    if @data.keys.length > 0
      last_id = @data.keys.max{|a,b| a.to_i <=> b.to_i} + 1
    end
    return { @data_field_id => last_id }
  end

  def create( args )
    if args.class != Hash
      dputs( 0 ){ "Entities.create takes a hash! You gave a #{args.class}" }
      exit
    end
    dputs( 5 ){ "Data_field_id is #{@data_field_id}" }
    if not args[ @data_field_id ]
      nid = new_id[@data_field_id]
      dputs( 3 ){ "Adding data_field_id of #{nid}" }
      args.merge!( { @data_field_id => nid } )
    end

    # Ask every storage-type whether he wants to change something in the
    # data
    @storage.each{|k, di| di.data_create( args ) }
    data_id = args[@data_field_id].to_i
    if not @data[ data_id ]
      @data[data_id] = { @data_field_id => data_id }
      dputs( 5 ){ "@data is now #{@data.inspect}" }
      dputs( 5 ){ "data_class is now #{@data_class.to_s}" }
      args.each{|k,v|
        set_entry( data_id, k, v )
      }
      save
      return get_data_instance( data_id )
    else
      @storage.each{|k, di| di.data_double( args ) }
      dputs( 2 ){ "Trying to create a double entry with data_id #{args[@data_field_id]}!" }
      return nil
    end
  end

  def save_data( d )
    dputs( 5 ){ "Saving #{d.inspect}" }
    d.to_sym!
    if d.has_key? @data_field_id
      # Assure that the data_field_id is an integer
      data_id = d[ @data_field_id ].to_i
      d[ @data_field_id ] = data_id
      e = get_data_instance( data_id )
      if not e
        dputs( 0 ){ "Didn't find key #{data_id.inspect}" }
        exit 1
      else
        e.data_set_hash( d, true )
      end
    else
      e = create( d )
    end

    save
    return e.data
  end

  def delete_id( id )
    id = id.to_i
    dputs( 3 ){ "Deleting id #{id}" }
    @data.delete( id )
    @data_instances.delete( id )
  end

  def set_entry( id, field, value )
    @storage.each{|k, di|
      if di.has_field field
        #        if value.to_s != @data[id.to_i][field].to_s
        val = di.set_entry( id, field, value )
        dputs( 4 ){ "#{id} - #{field} - #{value.inspect}" }
        @data[ id.to_i ][ field ] = val
        #        end
        return val
      end
    }
    nil
  end

  def get_entry( id, field )
    field = field.to_sym
    id = id.to_i
    # First look if there is a non-caching DataStorage
    @storage.each{|k, di|
      if di.has_field field and not di.data_cache
        dputs( 4 ){ "#{di} doesn't have data_cache for #{id} - #{field}" }
        val = di.get_entry( id, field )
        dputs( 4 ){ "#{id} - #{field} - #{val.inspect}" }
        @data[id][field] = val
        return val
      end
    }

    # Else get the things out of the cache
    if @data[id] and @data[id][field]
      @data[id][field]
    else
      nil
    end
  end

  def data_update( id )
    @data[id.to_i].each{|f,v|
      dputs( 5 ){ "Updating data for #{id} - #{f}" }
      get_entry( id, f )
    }
  end
  
  def migrate
    if not mv = MigrationVersions.match_by( :class_name, @name )
      dputs(2){"#{@name} has no migration yet"}
      mv = Entities.MigrationVersions.create( :class_name => @name,
        :version => 0 )
    end
    version = mv.version + 1
    dputs(3){"Checking for migration_#{version} of #{@name}"}
    while self.respond_to?( vers_str = "migration_#{version}".to_sym ) or
        self.respond_to?( vers_str = "migration_#{version}_raw".to_sym )
      dputs(2){"Migrating #{@name} to version #{version}, calling #{vers_str}"}
      dputs(4){"Working on #{data.inspect}"}
      @data.each{|k,v|
        if vers_str.to_s =~ /_raw$/
          dputs(4){"Sending raw data of #{v.inspect}"}
          send vers_str, v
          dputs(4){"raw data is now #{v.inspect}"}
          #@data[k] = v
        else
          inst = get_data_instance( k )
          dputs(4){"Sending #{inst.inspect}"}
          send vers_str, inst
        end
      }
      dputs(5){"Data is now #{@data.inspect}"}
      mv.version = version
      version += 1
    end
  end

  def load
    @data = {}
    @storage.each{|k,di|
      dputs( 5 ){ "Loading #{k} at #{di.name} with #{di.inspect}" }
      @data.merge!( di.load ){|k,o,n| o.merge(n) }
      dputs( 5 ){ "Loaded #{@data.inspect} for #{self.name}" }
    }
  end

  def save
    @storage.each{|k,di|
      dputs( 5 ){ "Saving #{k} at #{di.inspect}" }
      di.save( @data )
    }
  end

  def delete_all( local_only = false )
    @data_instances = {}
    @data = {}
    @storage.each{|k, di|
      di.delete_all( local_only )
    }
  end

end
