# An entity is mapped to more or less one service in the real world.
# It gives functions to easily handle different aspects of the arguments,
# which can be stored in it's own database, LDAP, or whatever else.
# Furthermore an easy interface for the viewers is generated, so that
# multiple viewers can display the same part of an Entity without having
# to copy code all over.

require 'Helpers/Value'
require 'Helpers/StorageType'
require 'Helpers/StorageHandler'
require 'Storages/CSV.rb'
require 'Storages/LDAP.rb'
require 'Storages/SQLite.rb'


class Array
  def sortk
    sort { |a, b| a.to_s <=> b.to_s }
  end
end

class Entities < RPCQooxdooService
  @@all = {}
  @@logging = true

  include StorageHandler

  attr_accessor :data_class, :data_instances, :blocks, :data_field_id,
                :storage, :data, :name, :msg, :undo, :logging, :keys,
                :save_after_create, :values, :changed, :null_allowed

  def initialize
    begin
      @data_class = eval(singular(self.class.name))
    rescue Exception => e
      # Just in case the data-class is not created yet
      eval("class #{singular(self.class.name)} < Entity\nend")
      @data_class = eval(singular(self.class.name))
    end
    @storage = nil
    @msg = nil
    @undo = @logging = false
    @last_id = 1
    @save_after_create = false
    @changed = false
    @null_allowed = false

    if @data_class != 'Entity'
      @@all[@data_class] = self
      dputs(4) { "Initializing #{self.class.name} with data_class = #{@data_class}" }

      # Initialize the basic variables
      @blocks = {}
      @values = []
      @data_instances = {}
      @default_type = :CSV
      @keys = {}

      # Check for config of this special class
      #      dputs( 2 ){ "Class is: #{self.class.name.to_sym.inspect}" }
      if @config = get_config(nil, :Entities, self.class.name)
        #@config = $config[:Entities][self.class.name.to_sym]
        dputs(3) { "Writing config #{@config.inspect} for #{self.class.name}" }
        @config.each { |k, v|
          dputs(3) { "Setting #{k} = #{v}" }
          case v
            when /true|false/
              instance_variable_set("@#{k.to_s}", eval(v))
            else
              instance_variable_set("@#{k.to_s}", v)
          end
          self.class.send(:attr_reader, k)
        }
      else
        @config = nil
      end

      # Stuff for the StorageHandler
      @storage = {}
      @data = {}
      @name = singular(self.class.name)
      @data_field_id = "#{@name}_id".downcase.to_sym

      # Now call the setup_data to initialize the fields
      value_block :default
      @load_data = true
      setup_data()

      # Finally adding @data_field_id to all storage-types
      dputs(4) { "Adding #{@data_field_id} to block" }
      value_block @data_field_id
      value_int_ALL @data_field_id

      dputs(4) { "Configuring all storages" }
      @storage.each { |k, s|
        dputs(4) { "Configuring #{k} #{s.inspect}" }
        s.configure(s.config)
      }
      dputs(4) { "Block is now: #{@blocks.inspect}" }
      if @load_data
        dputs(3) { "Loading data" }
        load
      else
        dputs(3) { "Not loading data because of false return-value of setup_data" }
      end
    end
  end

  # Here comes the definition of the data used in that Entity. If the
  # return-value is true, the data is loaded automatically
  def setup_data
    return false
  end

  # Gets the singular of a name
  def singular(name)
    case name
      when /ies$/
        return name.sub(/ies$/, "y")
      when /s$/
        return name.chop
    end
  end

  #
  # Generators for an Entity
  #

  # Starts a block of values to be displayed together. Takes optionally
  # an argument for the permissions neede, might be the same as another
  # permission. If no permission is given, the name of the block is used
  # as the name of the permission.
  # The final name of the permission is prepended by the name of the class!
  def value_block(*args)
    @block_now = args[0]
    @blocks[@block_now] = []
  end

  def value_add(cmds, args)
    value = Value.new(cmds, args, @default_type)
    @values.push value

    if not get_field_names.index value.name.to_sym
      # Prepare the entry in the blocks
      @blocks[@block_now].push(value)
    end

    # And add the entry in the DataHandler
    add_value_to_storage(value)
  end

  # Makes for a small proxy, in that only the needed classes are
  # instantiated - useful for stuff like long LDAP-lists...
  def get_data_instance(k)
    return nil if !k
    if k.class != Fixnum
      dputs(0) { "This is very bad" }
      dputs(0) { "value k is #{k.inspect}" }
      dputs(0) { "caller-stack is #{caller}" }
      raise "WrongIndex"
    end
    return nil if not k or not @data[k.to_i]
    if !@data_instances[k.to_i]
      @data_instances[k.to_i]= @data_class.new(@data[k.to_i][@data_field_id], self)
      @data_instances[k.to_i].init_instance
    end
    return @data_instances[k.to_i]
  end

  def match_by_id(k)
    get_data_instance(k)
  end

  # We can
  # - match_by_field - where the data is searched for the "field"
  # - search_by_field - where all data matching "field" is returned
  # - list_field - returns an array of all values of "field"
  # - listp_field - returns an array of arrays of all "data_field_id" and values of "field"
  # - value_type - adds an entry for a value of "type"
  def method_missing(cmd, *args)
    cmd_str = cmd.to_s
    dputs(5) { "Method missing: #{cmd}" }
    case cmd_str
      when /^match_(key|by)_(.*)/
        define_singleton_method(cmd_str.to_sym) { |arg| match_key($~[2], arg) }
        self.send(cmd_str.to_sym, *args)
      when /^create_key_(.*)/
        create_key($~[1])
      when /^(find|search|matches)(_by|)_/
        action = "#{$~[1]}#{$~[2]}"
        field = cmd_str.sub(/^(find|search|matches)(_by|)_/, "")
        dputs(4) { "Using #{action} for field #{field}" }
        if args[0].is_a? Entity
          dputs(4) { "Getting id because it's an Entity" }
          self.send(action, field, args[0].id)
        else
          self.send(action, field, args[0])
        end
      when /^list_/
        field = cmd_str.sub(/^list_/, "")
        dputs(5) { "Using list for field #{field}" }
        ret = @data.values.collect { |v| v[field.to_sym] }.sort { |a, b|
          a.downcase <=> b.downcase
        }
        dputs(4) { "Returning #{ret.inspect}" }
        ret
      when /^listp_/
        field = cmd_str.sub(/^listp_/, "")
        reverse = field =~ /^rev_/
        if reverse
          field.sub!(/^rev_/, "")
        end
        dputs(5) { "Using listpairs for field #{field.inspect}, #{@data.inspect}" }
        ret = @data.keys.collect { |k|
          dputs(4) { "k is #{k.inspect} - data is #{@data[k].inspect}" }
          [k, @data[k][field.to_sym]] }.sort { |a, b|
          a[1] <=> b[1]
        }
        reverse and ret.reverse!
        dputs(3) { "Returning #{ret.inspect}" }
        ret
      when /^value_/
        cmds = cmd_str.split("_")[1..-1]
        value_add(cmds, args)
      else
        dputs(0) { "Error: Method is missing: #{cmd} in Entities" }
        dputs(0) { caller.inspect }
        super cmd, *args
    end
  end

  def respond_to?(cmd)
    dputs(5) { cmd.inspect }
    if cmd =~ /^(match_by_|search_by_|list_|listp_|value_)/
      return true
    end
    super cmd
  end

  def whoami
    dputs(0) { "I'm !*2@#" }
  end

  # Log one action, with data, which is supposed to be a
  # Hash. Two possibilities:
  # [undo_function] - points to a function which can undo the operation. It will get "data" and "data_old", if applicable
  # [data_old] - eventual old data interesting to "undo_function"
  # It will return the index of the action
  def log_action(id, data, msg = nil, undo_function = nil, data_old = nil)
    @@logging and Entities.LogActions.log_action(@data_class, id, data, msg, undo_function, data_old)
  end

  # Checks for a list of it's own type, enhanced by filter
  def log_list(f = {})
    filter = {:data_class => @data_class}.merge(f)
    dputs(3) { "filter is #{filter}" }
    Entities.LogActions.log_list(filter)
  end

  # Undoes a given action
  def log_undo(action_id)
    Entities.LogActions.log_undo(self, action_id)
  end

  # Return an array of all available field-names as symbols
  def get_field_names(b = @blocks)
    ret = b.collect { |c|
      if c.class == Array
        get_field_names(c)
      elsif c.class == Value
        c.name
      else
        nil
      end
    }
    ret = ret.select { |s| s }
    ret.flatten.collect { |c| c.to_sym }
  end

  # Gets all field names of a block
  def get_block_fields(block)
    return [] unless @blocks.has_key? block.to_sym
    @blocks[block.to_sym].collect{|v|
      v.name
    }
  end

  # Returns the Value for an entry
  def get_value(n, b = @blocks)
    dputs(5) { "Name is #{n}" }
    n = n.to_sym
    b.each { |c|
      if c.class == Array
        v = get_value(n, c)
        dputs(5) { "Found array #{v.inspect}" }
        v and return v
      elsif c.class == Value
        if c.name.to_sym == n
          dputs(5) { "Found value #{c.inspect}" }
          return c
        end
      end
    }
    dputs(5) { "Found nothing" }
    return nil
  end

  def self.service(s)
    @@services_hash["Entities.#{s}"]
  end

  # For an easy Entities.Classname access to all entities stored
  # Might also be used by subclasses to directly acces the instance stored
  # in @@services_hash
  def self.method_missing(m, *args)
    dputs(5) { "I think I got a class: #{m}" }
    if self.name == "Entities"
      # This is for the Entities-class
      if ret = Entities.service(m)
        return ret
      else
        dputs(0) { "Method is missing: #{m} in Entries" }
        return super(m, *args)
      end
    else
      # We're in a subclass, so we first have to fetch the instance
      return Entities.service(self.name).send(m, *args)
    end
  end

  def self.delete_all_data(local_only = false)
    @@all.each_pair { |k, v|
      dputs(2) { "Erasing data of #{k}" }
      v.delete_all(local_only)
    }
  end

  def self.save_all(notmp = false)
    dputs(2) { 'Saving everything' }
    start = Time.now
    @@all.each { |k, v|
      dputs(3) { "Saving #{v.class.name}" }
      v.save(notmp: notmp)
    }
    dputs(2) { "Time for saving everything: #{Time.now - start}" }
  end

  def self.load_all
    dputs(2) { 'Loading everything' }
    @@all.each { |k, v|
      dputs(3) { "Loading #{v.class.name}" }
      v.load
    }
  end

  def self.is_setup?(e)
    ret = false
    @@all.keys.each { |k|
      ret |= k.to_s == "Entities::#{e}"
    }
    dputs(4) { "ret:#{ret} for #{e} with #{@@all.keys.inspect}" }
    ret
  end

  def self.has_entity?(a)
    dputs(4) { "Searching #{a.inspect} in #{@@all.keys.inspect}" }
    @@all.keys.each { |k|
      return true if k.name.to_s == a.to_s
    }
    return false
  end

  def self.needs(e)
    dputs(2) { "#{self.name} needs #{e}" }
    @@needs["Entities.#{self.name.to_s}"] = "Entities.#{e.to_s}"
  end

  def self.nolog(&b)
    oldlog = @@logging
    @@logging = false
    ret = yield b
    @@logging = oldlog
    ret
  end
end

#
# Defines one simple Entity
#
class Entity
  attr_reader :id
  attr_accessor :changed

  def initialize(id, proxy)
    dputs(5) { "Creating entity -#{proxy}- with id #{id}" }
    @id = id.to_i
    @proxy = proxy
    @changed = false
  end

  def init_instance
    @pre_init = true
    if true
      @proxy.values.each { |v|
        field = v.name
        if self.public_methods.index("#{field}=".to_sym) &&
            (value = data_get(field))
          dputs(3) { "Setting #{field} to #{value}" }
          send("#{field}=".to_sym, value)
        end
      }
    end

    setup_instance
    @pre_init = false
  end

  # Dummy setup - replace with real setup
  def setup_instance
  end

  alias_method :old_respond_to?, :respond_to?

  def respond_to?(cmd)
    field = cmd.to_s
    if field == "to_ary"
      dputs(4) { "not responding to_ary" }
      return false
    end
    case field
      when /=$/
        return true
      else
        return (@proxy.get_value(cmd) or super)
    end
  end

  def method_missing(cmd, *args)
    dputs(5) { "Entity#method_missing #{cmd} in #{self.class.name}," +
        " with #{args.inspect} and #{args[0].class}" }
    field = cmd.to_s
    if not @proxy.get_value(field.sub(/^_/, '').sub(/=$/, ''))
      dputs(0) { "ValueUnknown for #{cmd.inspect} in #{self.class.name} - " +
          "#{@proxy.blocks.inspect}" }
      if field =~ /^_/
        raise "ValueUnknown"
      else
        return super
      end
    end
    case field
      when /=$/
        # Setting the value
        dputs(5) { "data_set #{field} for class #{self.class.name}" }
        field_set = "_#{field.chop.sub(/^_/, '')}"

        if not old_respond_to? "#{field}".to_sym
          dputs(3) { "Creating method #{field} for #{self.class.name}" }
          dputs(4) { "Self is #{self.public_methods.sort.inspect}" }
          self.class.class_eval <<-RUBY
        def #{field}( v )
          if @proxy.undo or @proxy.logging
            data_set_log( "#{field_set}".to_sym, v, @proxy.msg, @proxy.undo, 
              @proxy.logging )
          else
            data_set( "#{field_set}".to_sym, v )
          end
          dputs(5){"Leaving =#{field_set}"}
        end
          RUBY
          dputs(4) { "Sending #{args[0]} to #{field}" }
          send(field, args[0])
        else
          dputs(0) { "#{field} is already defined - don't know what to do..." }
          caller.each { |c|
            dputs(0) { "Caller is #{c.inspect}" }
          }
        end
      else
        # Getting the value
        dputs(5) { "data_get #{field} for class #{self.class.name}" }

        if not old_respond_to? field
          self.class.class_eval <<-RUBY
        def #{field}
          data_get( "_#{field.sub(/^_/, '')}", false )
        end
          RUBY
          send(field)
        else
          dputs(0) { "#{field} is already defined - don't know what to do" }
          caller.each { |c|
            dputs(0) { "Caller is #{c.inspect}" }
          }
        end
      #      data_get( field )
    end
  end

  def to_hash(unique_ids = false)
    ret = @proxy.data[@id].dup
    dputs(5) { "Will return #{ret.to_a.join("-")}" }
    ret.each { |f, v|
      dputs(5) { "Doing field #{f} with #{v.inspect}" }
      #if data_get(f).is_a? Entity
      if value = @proxy.get_value(f) and value.dtype == "entity"
        dputs(5) { "Is an entity" }
        if unique_ids
          ret[f] = (d = data_get("_#{f}")) ? d.get_unique : nil
        else
          ret[f] = [v]
        end
      end
    }
    ret
  end

  # Show all logs for this entity
  def log_list(f = {})
    @proxy.log_list({:data_class_id => @id}.merge(f))
  end

  # Deletes the entry from the main part
  def delete
    @proxy.delete_id(@id)
  end

  def data
    if defined? @storage
      @storage.each { |k, di|
        if not di.data_cache
          @proxy.data_update(@id)
        end
      }
    end
    @proxy.data[@id]
  end

  def data_get(field, raw = false)
    ret = [field].flatten.collect { |f_orig|
      f = f_orig.to_s
      (direct = f =~ /^_/) and f.sub!(/^_/, '')
      dputs(4) { "Direct is #{direct.inspect} for #{f_orig.inspect}" }
      if (self.public_methods.index(f)) and (not direct)
        dputs(4) { "found direct method for #{f} in #{self.class}" }
        send(f)
      else
        dputs(4) { "Using proxy #{@proxy.class.name} for #{f}" }
        e = @proxy.get_entry(@id, f)
        dputs(5) { "e is #{e.inspect} from #{@proxy.data.inspect}" }
        if not raw and e
          v = @proxy.get_value(f)
          if e.class == Fixnum and v and v.dtype == 'entity'
            dputs(5) { "Getting instance for #{v.inspect}" }
            dputs(5) { "Getting instance with #{e.class} - #{e.inspect}" }
            dputs(5) { "Field = #{field}; id = #{@id}" }
            if e > 0 or @proxy.null_allowed
              e = v.eclass.get_data_instance([e].flatten.first)
            else
              return nil
            end
          elsif v and v.dtype == 'list_entity'
            dputs(4) { "Converting list_entity #{v.inspect} of #{e.inspect}" }
            e = e.collect { |val|
              v.eclass.get_data_instance(val)
            }
          end
        end
        e
      end
    }
    dputs(4) { "Return is #{ret.inspect}" }
    ret.length == 1 ? ret[0] : ret
  end

  def data_set(field_orig, value)
    field = field_orig.to_s
    (direct = field =~ /^_/) and field.sub!(/^_/, '')
    dputs(4) { "Direct is #{direct.inspect} for field #{field_orig.inspect}" }
=begin
    v = if value.is_a? Entity
      dputs( 3 ){ "Converting #{value} to #{value.id}" }
      value.id
    elsif value.is_a? Array
      dputs(3){"Storing an array #{value.inspect}"}
      dp value.collect{|val|
        val.is_a?( Entity ) ? val.id : val
      }
    else
      value
    end
=end
    v = value
    dputs(4) { "Self is #{self.public_methods.sort.inspect}" }
    if (self.public_methods.index("#{field}=".to_sym)) && (not direct)
      dputs(3) { "Setting #{field} through local method" }
      send("#{field}=".to_sym, v)
    else
      dputs(4) { "setting entry #{field} to #{v.inspect}" }
      @proxy.set_entry(@id, field, v)
      dputs(4) { 'Finished setting entry'
      }
    end
    @changed = true
    @proxy.changed = true
    self
  end

  # Save all data in the hash for which we have an entry
  # if create == true, it won't call LogActions for every field
  def data_set_hash(data, create = false)
    dputs(4) { "#{data.inspect} - #{create} - id is #{id}" }
    fields = @proxy.get_field_names
    data.each { |k, v|
      ks = k.to_sym
      # Only set data for which there is a field
      if fields.index(ks)
        dputs(4) { "Setting field #{ks}" }
        if create
          dputs(5) { "Creating without log" }
          data_set(ks, v)
        else
          dputs(4) { "Setting @data[#{k.inspect}] = #{v.inspect}" }
          data_set_log(ks, v, nil, (not create), (not create))
        end
      end
    }
    self
  end

  # Sets the value of a single entry and attaches an UNDO
  def data_set_log(field, value, msg = nil, undo = true, logging = true)
    dputs(5) { "For id #{@id}, setting entry #{field} to #{value.inspect} with undo being #{undo}" }
    old_value = data_get(field)
    new_value = data_set(field, value).data_get(field)
    dputs(5) { "new_value is #{new_value.class}" }
    if old_value.to_s != new_value.to_s
      dputs(3) { "Set field #{field} to value #{new_value.inspect}" }
      if logging
        field = field.to_s.sub(/^_/, '').to_sym
        if undo
          @proxy.log_action(@id, {field => new_value}, msg, :undo_set_entry, old_value)
        else
          @proxy.log_action(@id, {field => new_value}, msg)
        end
      end
    end
    self
  end

  def get_unique
    dputs(5) { "Unique for #{self.inspect}" }
    data_get(@proxy.data_field_id)
  end

  def true(*args)
    return true
  end

  def inspect
    #@id
    to_hash.inspect
  end

  def to_a
    dputs(5) { "to_a on #{self}" }
    [self]
  end

  def to_frontend
    [id, to_hash.collect { |k, v| v }.join(':')]
  end

  #def to_ary
  #  #[ to_hash.to_a ]
  #  dputs(5){"to_arying on #{self}"}
  #  [ self ]
  #end
end
