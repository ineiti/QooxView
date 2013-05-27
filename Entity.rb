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
    sort{|a,b| a.to_s <=> b.to_s }
  end
end



class Entities < RPCQooxdooService
  LOAD_DATA = true
  @@all = {}

  include StorageHandler

  attr_accessor :data_class, :data_instances, :blocks, :data_field_id, 
    :storage, :data, :name, :msg, :undo, :logging

  def initialize
    begin
      @data_class = eval( singular( self.class.name ) )
    rescue Exception => e
      # Just in case the data-class is not created yet
      eval( "class #{singular( self.class.name )} < Entity\nend" )
      @data_class = eval( singular( self.class.name ) )
    end
    @storage = nil
    @msg = nil
    @undo = @logging = true

    if @data_class != "Entity"
      @@all[ @data_class ] = self
      dputs( 4 ){ "Initializing #{self.class.name} with data_class = #{@data_class}" }

      # Initialize the basic variables
      @blocks = {}
      @data_instances = {}
      @default_type = :CSV

      # Check for config of this special class
      #      dputs( 2 ){ "Class is: #{self.class.name.to_sym.inspect}" }
      if $config and $config[:entities] and $config[:entities][self.class.name.to_sym]
        @config = $config[:entities][self.class.name.to_sym]
        dputs( 3 ){ "Writing config #{@config.inspect} for #{self.class.name}" }
        @config.each{ |k, v|
          begin
            instance_variable_set( "@#{k.to_s}", eval( v ) )
          rescue Exception => e
            instance_variable_set( "@#{k.to_s}", v )
          end
          self.class.send( :attr_reader, k )
          dputs( 3 ){ "Setting #{k} = #{v}" }
        }
      else
        @config = nil
      end

      # Stuff for the StorageHandler
      @storage = {}
      @data = {}
      @name = singular( self.class.name )
      @data_field_id = "#{@name}_id".downcase.to_sym

      # Now call the setup_data to initialize the fields
      value_block :default
      autoload = setup_data()

      # Finally adding @data_field_id to all storage-types
      dputs( 4 ){ "Adding #{@data_field_id} to block" }
      value_block @data_field_id
      value_int_ALL @data_field_id

      dputs(4){"Configuring all storages"}
      @storage.each{|k,s|
        dputs(4){"Configuring #{k} #{s.inspect}"}
        s.configure(s.config)
      }
      dputs( 4 ){ "Block is now: #{@blocks.inspect}" }
      if autoload 
        dputs( 3 ){"Loading data"}
        load
      else
        dputs( 3 ){"Not loading data because of false return-value of setup_data"}
      end
    end
  end

  # Here comes the definition of the data used in that Entity. If the
  # return-value is true, the data is loaded automatically
  def setup_data
    return false
  end

  # Gets the singular of a name
  def singular( name )
    case name
    when /ies$/
      return name.sub( /ies$/, "y" )
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
    @blocks[ @block_now ] = []
  end

  def value_add( cmds, args )
    value = Value.new( cmds, args, @default_type )

    if not get_field_names.index value.name.to_sym
      # Prepare the entry in the blocks
      @blocks[ @block_now ].push( value )
    end

    # And add the entry in the DataHandler
    add_value_to_storage( value )
  end

  # Makes for a small proxy, in that only the needed classes are
  # instantiated - useful for stuff like long LDAP-lists...
  def get_data_instance( k )
    return nil if not k or not @data[k.to_i]
    @data_instances[k.to_i] ||= @data_class.new( @data[k.to_i][@data_field_id], self )
    return @data_instances[k]
  end

  def match_by_id( k )
    get_data_instance( k )
  end

  # We can
  # - match_by_field - where the data is searched for the "field"
  # - search_by_field - where all data matching "field" is returned
  # - list_field - returns an array of all values of "field"
  # - listp_field - returns an array of arrays of all "data_field_id" and values of "field"
  # - value_type - adds an entry for a value of "type"
  def method_missing( cmd, *args )
    cmd_str = cmd.to_s
    dputs( 5 ){ "Method missing: #{cmd}" }
    case cmd_str
    when /^(find|search|match|matches)(_by|)_/
      action = "#{$~[1]}#{$~[2]}"
      field = cmd_str.sub( /^(find|search|match|matches)(_by|)_/, "" )
      dputs( 4 ){ "Using #{action} for field #{field}" }
      self.send( action, field, args[0] )
    when /^list_/
      field = cmd_str.sub( /^list_/, "" )
      dputs( 5 ){ "Using list for field #{field}" }
      ret = @data.values.collect{|v| v[field.to_sym]}
      dputs( 4 ){ "Returning #{ret.inspect}" }
      ret
    when /^listp_/
      field = cmd_str.sub( /^listp_/, "" )
      reverse = field =~ /^rev_/
      if reverse
        field.sub!( /^rev_/, "" )
      end
      dputs( 5 ){ "Using listpairs for field #{field.inspect}, #{@data.inspect}" }
      ret = @data.keys.collect{|k|
        dputs( 4 ){ "k is #{k.inspect} - data is #{@data[k].inspect}" }
        [k, @data[k][field.to_sym] ] }.sort{|a,b|
        a[1] <=> b[1]
      }
      reverse and ret.reverse!
      dputs( 3 ){ "Returning #{ret.inspect}" }
      ret
    when /^value_/
      cmds = cmd_str.split("_")[1..-1]
      value_add( cmds, args )
    else
      dputs( 0 ){ "Method is missing: #{cmd} in Entities" }
      super cmd, *args
    end
  end

  def respond_to?( cmd )
    dputs( 5 ){ cmd.inspect }
    if cmd =~ /^(match_by_|search_by_|list_|listp_|value_)/
      return true
    end
    super cmd
  end

  def whoami
    dputs( 0 ){ "I'm !*2@#" }
  end

  # Log one action, with data, which is supposed to be a
  # Hash. Two possibilities:
  # [undo_function] - points to a function which can undo the operation. It will get "data" and "data_old", if applicable
  # [data_old] - eventual old data interesting to "undo_function"
  # It will return the index of the action
  def log_action( id, data, msg = nil, undo_function = nil, data_old = nil )
    Entities.LogActions.log_action( @data_class, id, data, msg, undo_function, data_old )
  end

  # Checks for a list of it's own type, enhanced by filter
  def log_list( f = {} )
    filter = {:data_class => @data_class}.merge( f )
    dputs( 3 ){ "filter is #{filter}" }
    Entities.LogActions.log_list( filter )
  end

  # Undoes a given action
  def log_undo( action_id )
    Entities.LogActions.log_undo( self, action_id )
  end

  # Return an array of all available field-names as symbols
  def get_field_names( b = @blocks )
    ret = b.collect{|c|
      if c.class == Array
        get_field_names( c )
      elsif c.class == Value
        c.name
      else
        nil
      end
    }
    ret = ret.select{|s| s }
    ret.flatten.collect{|c| c.to_sym }
  end

  # Returns the Value for an entry
  def get_value( n, b = @blocks )
    dputs(5){"Name is #{n}"}
    n = n.to_sym
    b.each{|c|
      if c.class == Array
        v = get_value( n, c )
        dputs(5){"Found array #{v.inspect}"}
        v and return v
      elsif c.class == Value
        if c.name.to_sym == n
          dputs(5){"Found value #{c.inspect}"}
          return c
        end
      end
    }
    dputs(5){"Found nothing"}
    return nil
  end

  def self.service( s )
    @@services_hash["Entities.#{s}"]
  end

  # For an easy Entities.Classname access to all entities stored
  # Might also be used by subclasses to directly acces the instance stored
  # in @@services_hash
  def self.method_missing(m,*args)
    dputs( 5 ){ "I think I got a class: #{m}" }
    if self.name == "Entities"
      # This is for the Entities-class
      if ret = Entities.service( m )
        return ret
      else
        dputs( 0 ){ "Method is missing: #{m} in Entries" }
        return super( m, *args )
      end
    else
      # We're in a subclass, so we first have to fetch the instance
      return Entities.service( self.name ).send( m, *args )
    end
  end

  def self.delete_all_data( local_only = false )
    @@all.each_pair{|k,v|
      dputs( 1 ){ "Erasing data of #{k}" }
      v.delete_all( local_only )
    }
  end

  def self.save_all
    @@all.each{|k,v|
      dputs( 0 ){ "Saving #{v.class.name}" }
      v.save
    }
  end

  def self.load_all
    @@all.each{|k,v|
      dputs( 3 ){ "Loading #{v.class.name}" }
      v.load
    }
  end
end



#
# Defines one simple Entity
#
class Entity
  attr_reader :id
  def initialize( id, proxy )
    dputs( 5 ){ "Creating entity -#{proxy}- with id #{id}" }
    @id = id.to_i
    @proxy = proxy

    setup_instance
  end

  # Dummy setup - replace with real setup
  def setup_instance
  end

  def method_missing( cmd, *args )
    dputs( 5 ){ "Entity#method_missing #{cmd}, with #{args} and #{args[0].class}" }
    field = cmd.to_s
    case field
    when /=$/
      dputs( 5 ){ "data_set #{field} for class #{self.class.name}" }
      # Setting the value
      field = field.chop.to_sym
      
      if not old_respond_to? "#{field}=".to_sym
        self.class.class_eval <<-RUBY
        def #{field}=( v )
          if @proxy.undo or @proxy.logging
            data_set_log( "#{field}".to_sym, v, @proxy.msg, @proxy.undo, @proxy.logging )
          else
            data_set( "#{field}".to_sym, v )
          end
        end
        RUBY
        send( "#{field}=".to_sym, args[0] )
      else
        dputs(0){"#{field}= is already defined - don't know what to do..."}
        caller.each{|c|
          dputs(0){"Caller is #{c.inspect}"}          
        }
      end
    else
      # Getting the value
      dputs( 5 ){ "data_get #{field} for class #{self.class.name}" }
      if not old_respond_to? field
        self.class.class_eval <<-RUBY
        def #{field}
          data_get( "#{field}" )
        end
        RUBY
        send( field )
      else
        dputs(0){"#{field} is already defined - don't know what to do"}
        caller.each{|c|
          dputs(0){"Caller is #{c.inspect}"}          
        }
      end
      #      data_get( field )
    end
  end

  alias_method :old_respond_to?, :respond_to?
  
  def respond_to?(cmd)
    field = cmd.to_s
    case field
    when /=$/
      return true
    else
      return ( data_get( field ) or super )
    end
  end

  def to_hash( unique_ids = false )
    ret = @proxy.data[@id].dup
    dputs( 5 ){ "Will return #{ret.to_a.join("-")}" }
    ret.each{|f,v|
      dputs(5){"Doing field #{f} with #{v.inspect}"}
      #if data_get(f).is_a? Entity
      if value = @proxy.get_value(f) and value.dtype == "entity"
        dputs(5){"Is an entity"}
        if unique_ids
          ret[f] = data_get(f).get_unique
        else
          ret[f] = [v]
        end
      end
    }
    ret
  end

  # Show all logs for this entity
  def log_list( f = {} )
    @proxy.log_list( { :data_class_id => @id }.merge(f) )
  end

  # Deletes the entry from the main part
  def delete
    @proxy.delete_id( @id )
  end

  def data
    if defined? @storage
      @storage.each{|k, di|
        if not di.data_cache
          @proxy.data_update( @id )
        end
      }
    end
    @proxy.data[@id]
  end

  def data_get( field, raw = false )
    ret = [field].flatten.collect{|f|
      e = @proxy.get_entry( @id, f.to_s )
      if not raw
        v = @proxy.get_value( f )
        if e and v and v.dtype == "entity"
          dputs( 5 ){ "Getting instance for #{v.inspect}" }
          dputs( 5 ){ "Getting instance with #{e.inspect}" }
          e = v.eclass.get_data_instance( e )
        end
      end
      e
    }
    dputs(4){"Return is #{ret.inspect}"}
    ret.length == 1 ? ret[0] : ret
  end

  def data_set( field, value )
    if value.is_a? Entity
      dputs( 3 ){ "Converting #{value} to #{value.id}" }
      @proxy.set_entry( @id, field, value.id )
    else
      @proxy.set_entry( @id, field, value )
    end
    self
  end

  # Save all data in the hash for which we have an entry
  # if create == true, it won't call LogActions for every field
  def data_set_hash( data, create = false )
    dputs( 4 ){ "#{data.inspect} - #{create} - id is #{id}" }
    fields = @proxy.get_field_names
    data.each{|k,v|
      ks = k.to_sym
      # Only set data for which there is a field
      if fields.index( ks )
        dputs(4){"Setting field #{ks}"}
        if create
          dputs(5){"Creating without log"}
          data_set( ks, v )
        else
          dputs( 3 ){ "Setting @data[#{k.inspect}] = #{v.inspect}" }
          data_set_log( ks, v, nil, ( not create ), ( not create ) )
        end
      end
    }
    self
  end

  # Sets the value of a single entry and attaches an UNDO
  def data_set_log( field, value, msg = nil, undo = true, logging = true )
    dputs( 5 ){ "For id #{@id}, setting entry #{field} to #{value.inspect} with undo being #{undo}" }
    old_value = data_get( field )
    new_value = data_set( field, value ).data_get( field )
    dputs( 5 ){ "new_value is #{new_value.class}" }
    if old_value.to_s != new_value.to_s
      dputs( 3 ){ "Set field #{field} to value #{new_value.inspect}" }
      if logging
        if undo
          @proxy.log_action( @id, { field => new_value }, msg, :undo_set_entry, old_value )
        else
          @proxy.log_action( @id, { field => new_value }, msg )
        end
      end
    end
    self
  end
  
  def get_unique
    dputs(5){"Unique for #{self.inspect}"}
    data_get( @proxy.data_field_id )
  end

  def true( *args )
    return true
  end

  def inspect
    #@id
    to_hash.inspect
  end
end
