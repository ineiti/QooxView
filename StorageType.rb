=begin
  Interface-class for entities. Must provide:

  * init( name ) - initialises the data using "name" as the name of the class
  * addField( name, type ) - adds a field to the data
  * setField( name, data ) - sets the data of a field
  * getField( name ) - returns the data of a field
  * save - saves the whole entity
  * load - loads the whole entity
  * search - searches in the whole entity
=end

class StorageType
  @@types = {}
  attr_reader :data_cache, :name
  
  def initialize( entity, config = {} )
    @name = entity.name
    @entity = entity
    @data_field_id = entity.data_field_id
    @fields = {}
    @data_cache = true
    
    class_name = self.class.name.to_sym
    if $config and $config[:StorageType] and $config[:StorageType][class_name]
      config = $config[:StorageType][class_name].merge( config )
    end
    configure( config )
  end
  
  # By default use configuration-options to overwrite class-variables
  def configure( config )
    config.each{|k,v|
      dputs 3, "Putting configuration #{v.inspect} for #{k.inspect}"
      eval "@#{k} = v"
    }
  end
  
  def add_field( name, args )
    if not has_field name
      @fields[name.to_sym] = args
    else
      @fields[name.to_sym].merge!( args )
    end
  end
  
  def has_field( name )
    @fields.has_key? name.to_sym
  end
  
  def field_args( name )
    if has_field name
      return @fields[name.to_sym].dup
    end
  end
  
  # Returns only the relevant part of the data
  def extract_data( d )
    ret = {}
     ( @fields.keys + [ @data_field_id ] ).uniq.each{|k| 
      ret.merge! k => d[k]
    }
    ret
  end
  
  # Calls the block for each data that has more than one key in it
  def data_each( data )
    dputs 5, data.inspect
    dputs 5, data.values.inspect
    data.values.sort{|s, t|
      #dputs 3, s.inspect
      #dputs 4, t.inspect
      s[@data_field_id] <=> t[@data_field_id]
    }.each{|d|
      dw = extract_data( d )
      if dw.size > 1
        yield dw
      end
    }
  end
  
  def set_entry( data, field, value )
    return value
  end
  
  def method_missing( name, *arg )
    case name
      when /^(init|addField|setField|getField|save|load|search)$/
      dputs 0, "Must provide #{name}!"
      exit 0
    else
      super( name, arg )
    end
  end
  
  # Should delete all stored values - only really used for tests
  def delete_all( local_only = false )
  end
  
  # Before a new data-set is created, ever StorageType has the
  # possibility to adjust the data
  def data_create( data )  
  end
  
  # If a double-entry has been detected after creation
  def data_double( data )  
  end
  
  def self.new_st( st, entity, config = {} )
    if StorageType.has? st
      return @@types[st.to_sym].new( entity, config )
    end
  end
  
  def self.inherited( subclass )
    dputs 2, "Added #{subclass} to StorageTypes"
    @@types[subclass.name.to_sym] = subclass
    super( subclass )
  end
  
  def self.has?( t )
    t and @@types.has_key? t.to_sym
  end
  
  def self.data_save( index = nil )
    
  end
  
  def self.data_load
    
  end
end
