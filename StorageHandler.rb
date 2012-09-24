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
            dputs 2, "Replacing #{k.inspect} with #{v.inspect}"
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
      dputs 0, "Can't find StorageType of -#{st.inspect}-"
      exit 1
    end

    if has_storage? st
      dputs 3, "Storage-type -#{st}- already exists"
    else
      dputs 3, "Adding storage-type -#{st}-"
      @storage[ st ] = StorageType.new_st( st, self, config )
      dputs 3, "@storage is #{@storage.inspect}"
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
    #dputs 5, "( #{field}, #{value} ) with #{@data.inspect}"
    @data.each_key{|k|
    # dputs 5, "Searching :#{value}: in #{field} of #{k} which is :#{@data[k][field.to_sym]}:"
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
    #dputs 5, "Searching :#{value}: in #{field} of #{k} which is :#{@data[k][field.to_sym]}:"
      if @data[k]
        [@data[k][field]].flatten.each{|d|
          if d.to_s =~ /#{value.to_s}/i
            dputs 4, "Found data-entry #{k}: #{@data[k].inspect}"
            result.push get_data_instance( k )
          end
        }
      end
    }
    return result
  end
	
	# Like search_by, but only exact matches
	def match_by( field, value )
		search_by( field, "^#{value}$" )
	end
  
  # filter is a hash with field/value-pairs to be searched.
  def filter_by( filter )
    keys = filter.keys
    key = keys.shift
    res = search_by( key, filter[key] ).collect{|r| r.data}
    # Refine the search
    keys.each{|k|
      res = res.select{|r|
        dputs 5, "Searching results for #{[r, k, filter[k]].inspect}"
        r.has_key? k and r[k].to_s =~ /#{filter[k].to_s}/i
      }
    }
    res
  end

  def new_id
    last_id = 0
    if @data.keys.length > 0
      last_id = @data.keys.max{|a,b| a.to_i <=> b.to_i} + 1
    end
    return { @data_field_id => last_id }
  end

  def create( args )
    if args.class != Hash
      dputs 0, "Entities.create takes a hash! You gave a #{args.class}"
      exit
    end
		dputs 5, "Data_field_id is #{@data_field_id}"
    if not args[ @data_field_id ]
			dputs 5, "Adding data_field_id"
      args.merge!( { @data_field_id => new_id[@data_field_id] } )
    end

    # Ask every storage-type whether he wants to change something in the
    # data
    @storage.each{|k, di| di.data_create( args ) }
    key = args[@data_field_id]
    if not @data[ key ]
      @data[key] = { @data_field_id => key }
      dputs 5, "@data is now #{@data.inspect}"
      dputs 5, "data_class is now #{@data_class.to_s}"
      save_data( args )
      return get_data_instance( key )
    else
      @storage.each{|k, di| di.data_double( args ) }
      dputs 2, "Trying to create a double entry!"
      return nil
    end
  end

  def save_data( data )
    dputs 5, "Saving #{data.inspect}"
    data.to_sym!
    if data.has_key? @data_field_id
      data_id = data[ @data_field_id ].to_i
      # Assure that the data_field_id is an integer
      data[ @data_field_id ] = data_id
      e = get_data_instance( data_id )
      if not e
        dputs 0, "Didn't find key #{data_id.inspect}"
        exit 1
      else
      e.data_set_hash( data, true )
      end
    else
      e = create( data )
    end

    dputs 3, "Saving data #{data_id}"
    @storage.each{|k,c|
      c.save( @data )
    }
    return e.data
  end

  def delete_id( id )
    id = id.to_i
    dputs 3, "Deleting id #{id}"
    @data.delete( id )
    @data_instances.delete( id )
  end

  def set_entry( id, field, value )
    @storage.each{|k, di|
      if di.has_field field
        if value.to_s != @data[id.to_i][field]
          val = di.set_entry( id, field, value )
          dputs 4, "#{id} - #{field} - #{value.inspect}"
        @data[ id.to_i ][ field ] = val
        end
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
        dputs 4, "#{di} doesn't have data_cache for #{id} - #{field}"
        val = di.get_entry( id, field )
        dputs 4, "#{id} - #{field} - #{val.inspect}"
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
      dputs 5, "Updating data for #{id} - #{f}"
      get_entry( id, f )
    }
  end

  def load
    @data = {}
    @storage.each{|k,di|
      dputs 5, "Loading #{k} at #{di.name} with #{di.inspect}"
      @data.merge!( di.load ){|k,o,n| o.merge(n) }
			dputs 4, "Loaded #{@data.inspect}"
    }
  end

  def save
    @storage.each{|k,di|
      dputs 5, "Saving #{k} at #{di.inspect}"
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
