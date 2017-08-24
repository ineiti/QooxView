=begin
Holds all DataTypes for an entity
=end

module StorageHandler
  # Checks whether there is a configuration-option which wants to replace
  # the StorageType
  def replace_st(st)
    if get_config(false, :StorageHandler, :Replace)
      $config[:StorageHandler][:Replace].each { |k, v|
        if st.to_sym == k.to_sym
          dputs(3) { "Replacing #{k.inspect} with #{v.inspect}" }
          st = v.to_sym
        end
      }
    end
    st.to_sym
  end

  # Adds a new value to the storages to hold the appropriate values.
  def add_value_to_storage(value)
    return if !value.st
    args = value.args.merge(:dtype => value.dtype)
    if value.st != 'ALL'
      st = replace_st(value.st)
      if not @storage.has_key? st
        # A request for another type
        add_new_storage(st)
      end
      @storage[st].add_field(value.name, args)
    else
      @storage.each { |k, v|
        v.add_field(value.name, args)
      }
    end
  end

  def field_args(name)
    @storage.each { |k, v|
      if v.has_field name
        return v.field_args name
      end
    }
    nil
  end

  # Adds a new storage type - returns the new created or already initialised storage-type
  def add_new_storage(st, config = {})
    st = replace_st(st)

    if !StorageType.has? st
      dputs(0) { "Can't find StorageType of -#{st.inspect}-" }
      exit 1
    end

    if has_storage? st
      dputs(3) { "Storage-type -#{st}- already exists" }
    else
      dputs(3) { "Adding storage-type -#{st}-" }
      @storage[st] = StorageType.new_st(st, self, config)
      dputs(3) { "@storage is #{@storage.inspect}" }
    end

    @storage[st]
  end

  def has_storage?(st)
    @storage ? (@storage.has_key? st.to_sym) : false
  end

  def has_field?(f)
    @storage.each { |k, v|
      if v.has_field f
        return true
      end
    }
    return false
  end

  # Have a handler for the ActiveRecord-type match_by_ and the name
  # of the field to search for
  def find_key_by(field, value)
    #dputs( 5 ){ "( #{field}, #{value} ) with #{@data.inspect}" }
    @data.each_key { |k|
      dputs(5) { "Searching :#{value}: in #{field} of #{k} which is "+
          ":#{@data[k][field.to_sym].to_s}: " }
      #if @data[k] and @data[k][field.to_sym].to_s.downcase == value.to_s.downcase
      if @data[k] and (@data[k][field.to_sym].to_s =~ /#{value.to_s}/i)
        return k
      end
    }
    return nil
  end

  def find(field, value)
    result = find_by(field, value)
    return result ? result.data : nil
  end

  def find_by(field, value)
    key = find_key_by(field, value)
    return key ? get_data_instance(key) : nil
  end

  def search_all_
    @data.each_key.collect { |k|
      get_data_instance(k)
    }
  end

  # Searching of misuse in search_all - found and accepted misuses can take
  # search_all_
  def search_all
    # log_msg :StorageHandler, "Search_all for #{self.name} in #{caller.inspect}"
    search_all_
  end

  # Similar to find_by, but searches multiple instances that are similar to the
  # value, returns the instances
  def search_by(field, value)
    result = []
    field = field.to_sym
    @data.each_key { |k|
      #dputs( 5 ){ "Searching :#{value}: in #{field} of #{k} which is :#{@data[k][field.to_sym]}:" }
      if @data[k]
        [@data[k][field]].flatten.each { |d|
          if d.to_s =~ /#{value.to_s}/i
            dputs(4) { "Found data-entry #{k}: #{@data[k].inspect}" }
            result.push get_data_instance(k)
          end
        }
      end
    }
    return result.uniq
  end

  # Similar to search_by, but searches multiple instances that contain all elements
  # of 'values'
  def search_by_all(field, values)
    #dputs_func
    result = []
    field = field.to_sym
    @data.each_key { |k|
      #dputs( 5 ){ "Searching :#{value}: in #{field} of #{k} which is :#{@data[k][field.to_sym]}:" }
      if @data[k]
        found_data = true
        values.each { |value|
          found = false
          [@data[k][field]].flatten.each { |d|
            dputs(4) { "Searching for #{value.inspect} in #{k}: #{d.inspect}" }
            if d.to_s =~ /#{value.to_s}/i
              found = true
            end
          }
          found_data &= found
        }
        if found_data
          dputs(4) { "Found data-entry #{k}: #{@data[k].inspect}" }
          result.push get_data_instance(k)
        end
      end
    }
    return result.uniq
  end

  # Like search_by, but only ONE EXACT match
  def match_by(field, value)
    field = field.to_sym
    v = value.is_a?(Entity) ? value.id : value.to_s
    @data.each_key { |k|
      if @data[k]
        [@data[k][field]].flatten.each { |d|
          dputs(5) { "Searching #{v} in #{d} of #{@data[k].inspect}" }
          if d.to_s == v
            dputs(4) { "Found data-entry #{k}: #{@data[k].inspect}" }
            return get_data_instance(k)
          end
        }
      end
    }
    return nil
  end

  # Like search_by, but only EXACT matcheS
  def matches_by(field, value)
    ret = search_by(field, "^#{value}$")
    return ret
  end

  # filter is a hash with field/value-pairs to be searched.
  def filter_by(filter)
    keys = filter.keys
    key = keys.shift
    res = search_by(key, filter[key]).collect { |r| r.data }
    # Refine the search
    keys.each { |k|
      res = res.select { |r|
        dputs(5) { "Searching results for #{[r, k, filter[k]].inspect}" }
        r.has_key? k and r[k].to_s =~ /#{filter[k].to_s}/i
      }
    }
    res.map{|r|
      get_data_instance(r[@data_field_id])
    }
  end

  def new_id
    #    last_id = 1
    #    if @data.keys.length > 0
    #      last_id = @data.keys.max{|a,b| a.to_i <=> b.to_i} + 1
    #    end
    while @data.has_key? @last_id
      dputs(5) { "Already having id #{@last_id}" }
      @last_id += 1
    end
    return {@data_field_id => @last_id}
  end

  def create(args, allow_double = false)
    # dputs_func
    oldload = @loading
    @loading = true
    if args.class != Hash
      dputs(0) { "Entities.create takes a hash! You gave a #{args.class}" }
      exit
    end
    dputs(5) { "Data_field_id is #{@data_field_id}" }
    if not args[@data_field_id]
      nid = new_id[@data_field_id]
      dputs(3) { "Adding data_field_id of #{nid}" }
      args.merge!({@data_field_id => nid})
    end

    # Ask every storage-type whether he wants to change something in the
    # data
    dputs(3) { "Asking storages to intervene for #{self.class.name}" }
    @storage.each { |k, di|
      dputs(3) { "Intervention from #{k.inspect}" }
      di.data_create(args)
    }
    data_id = args[@data_field_id].to_i
    if not @data[data_id] or allow_double
      if @data[data_id]
        dputs(0) { "Error: creating double-entry #{args.inspect}" }
      end
      @data[data_id] = {@data_field_id => data_id}
      dputs(5) { "@data is now #{@data.inspect}" }
      dputs(5) { "data_class is now #{@data_class.to_s}" }
      args.each { |k, v|
        set_entry(data_id, k, v)
      }
      @save_after_create and save
      update_key(data_id)
      d = get_data_instance(data_id)
      @changed = d.changed = true
      @loading = oldload
      return d
    else
      @storage.each { |k, di| di.data_double(args) }
      dputs(2) { "Trying to create a double entry with data_id #{args[@data_field_id]}!" }
      @loading = oldload
      return nil
    end
  end

  def save_data(d)
    #dputs_func
    dputs(5) { "Saving #{d.inspect}" }
    d.to_sym!
    if d.has_key? @data_field_id
      # Assure that the data_field_id is an integer
      dputs(5) { 'Has key' }
      data_id = d[@data_field_id].to_i
      d[@data_field_id] = data_id
      e = get_data_instance(data_id)
      if not e
        dputs(0) { "Didn't find key #{data_id.inspect}" }
        exit 1
      else
        dputs(5) { "Setting hash #{d.inspect}" }
        e.data_set_hash(d, true)
      end
    else
      e = create(d)
    end

    save
    return e.data
  end

  def delete_id(id)
    id = id.to_i
    dputs(3) { "Deleting id #{id}" }
    @data.delete(id)
    @data_instances.delete(id)
    @storage.each{|k, di|
      di.delete id
    }
    @changed = true
  end

  def set_entry(id, field, v)
    #dputs_func
    value = if v.is_a? Entity
              dputs(3) { "Converting #{v} to #{v.id}" }
              v.id
            elsif v.is_a? Array
              dputs(3) { "Storing an array #{v.inspect}" }
              v.collect { |val|
                val.is_a?(Entity) ? val.id : val
              }
            else
              v
            end
    field = field.to_sym
    dputs(4) { "Storing #{value} in #{field} for id #{id} in data #{@data}" }
    @storage.each { |k, di|
      if di.has_field field
        if !@data[id.to_i].has_key?(field) or
            value.to_s != @data[id.to_i][field].to_s
          val = di.set_entry(id, field, value)
          dputs(4) { "#{id} - #{field} - #{value.inspect}" }
          @data[id.to_i][field] = val
        elsif DEBUG_LVL >= 4
          log_msg 'StorageHandler', 'Trying to overwrite with same value in ' +
                                      "#{self.class.name}-#{field}-#{value.to_s}\n" +
                                      caller.inspect
        end
        update_key(id.to_i)
        return val
      end
    }
    nil
  end

  def get_entry(id, field)
    field = field.to_sym
    id = id.to_i
    # First look if there is a non-caching DataStorage
    @storage.each { |k, di|
      dputs(5) { "Storage is #{di}" }
      if di.has_field field and not di.data_cache
        dputs(4) { "#{di} doesn't have data_cache for #{id} - #{field}" }
        val = di.get_entry(id, field)
        if val.class == String
          val.force_encoding(Encoding::UTF_8)
        end
        dputs(4) { "#{id} - #{field} - #{val.inspect}" }
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

  def data_update(id)
    @data[id.to_i].each { |f, v|
      dputs(5) { "Updating data for #{id} - #{f}" }
      get_entry(id, f)
    }
  end

  def migrate
    #dputs_func
    if not mv = MigrationVersions.match_by(:class_name, @name)
      dputs(2) { "#{@name.inspect} has no migration yet" }
      mv = Entities.MigrationVersions.create(:class_name => @name,
                                             :version => 0)
    end
    version = mv.version + 1
    dputs(3) { "Checking for migration_#{version} of #{@name}" }
    while self.respond_to?(vers_str = "migration_#{version}".to_sym) ||
        self.respond_to?(vers_str = "migration_#{version}_raw".to_sym)
      if @dont_migrate
        log_msg :Migration, "Just counting migrations for #{name}: #{version}"
      else
        # log_msg :Migration, "Migrating #{@name} to version #{version}, calling #{vers_str}"
        dputs(4) { "Working on #{data.inspect}" }
        @data.each { |k, v|
          if vers_str.to_s =~ /_raw$/
            dputs(4) { "Sending raw data of #{v.inspect}" }
            send vers_str, v
            dputs(4) { "raw data is now #{v.inspect}" }
            #@data[k] = v
          else
            inst = get_data_instance(k)
            dputs(4) { "Sending #{inst.inspect}" }
            send vers_str, inst
          end
        }
        dputs(5) { "Data is now #{@data.inspect}" }
        @changed = true
      end
      mv.version = version
      version += 1
    end
    @changed and save
  end

  def load(has_static = true)
    #dputs_func
    return if @is_loaded
    dep = RPCQooxdooService.needs["Entities.#{self.class.name}"]
    dputs(2) { "Loading #{self.class.name} - #{dep}" }
    if dep
      dep.each { |pre|
        pre_class = RPCQooxdooService.services[pre]
        pre_class.is_loaded and next
        dputs(3) { "Pre-loading #{pre}" }
        pre_class.load
      }
    end
    @data = {}
    @data_instances = {}
    @keys = {}
    @storage.each { |k, di|
      dputs(5) { "Loading #{k} at #{di.name} with #{di.inspect}" }
      @data.merge!(di.load) { |k, o, n| o.merge(n) }
      dputs(5) { "Loaded #{@data.inspect} for #{self.name}" }
    }
    if @data.length == 0 && respond_to?(:init)
      dputs(1) { "Calling init for #{self.name}" }
      init
      @dont_migrate = true
    end
    @last_id = @data.length > 0 ? @data.to_a.last[0] : 1
    has_static and @static = Statics.get_hash("Entities.#{@name}")

    @is_loaded = true
    respond_to?(:loaded) and loaded
  end

  def save
    return unless @changed
    @storage.each { |k, di|
      dputs(5) { "Saving #{k} at #{di.inspect}" }
      di.save(@data)
    }
    @changed = false
  end

  def delete_all(local_only = false)
    dputs(3) { "Deleting all of #{self.class.name}" }
    @data_instances = {}
    @data = {}
    @keys = {}
    @storage.each { |k, di|
      di.delete_all(local_only)
    }
    @static = Statics.get_hash("Entities.#{@name}")
    @last_id = 1
    @is_loaded = false
    @dont_migrate = false
  end

  def create_key(name)
    name = name.to_sym
    if @keys.has_key? name
      dputs(2) { "#{self.class.name} already has key #{name}" }
    else
      entries = {}
      @data.each_pair { |k, v|
        dputs(5) { "Adding #{name} = #{v[name]} in #{v.inspect}" }
        entries[v[name].to_s] = k
      }
      dputs(4) { "Setting keys[#{name}] to #{entries.inspect}" }
      @keys[name] = entries
    end
  end

  def match_key(name, entry)
    dputs(5) { "Matching #{entry} of #{name} in #{@keys.inspect}" }
    name = name.to_sym
    @keys.has_key? name or create_key(name)
    e = entry.is_a?(Entity) ? entry.id.to_s : entry.to_s
    get_data_instance(@keys[name][e])
  end

  def update_key(id)
    dputs(5) { "Updating keys #{@keys.inspect} for #{id}" }
    @keys.each_key { |k|
      @keys[k].merge!(@data[id][k].to_s => id)
    }
  end

  def first
    key = @data.first
    return key ? get_data_instance(key[0]) : nil
  end

  def last
    key = @data.last
    return key ? get_data_instance(key[0]) : nil
  end
end
