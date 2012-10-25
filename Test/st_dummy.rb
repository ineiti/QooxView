class STdummy1 < StorageType
  attr_accessor :conf, :fields
  
  def load
    {}
  end
  
  def save( data )
    
  end

end

class STdummy2 < STdummy1
  
  def configure( config )
    dputs( 3 ){ "Configuration of STdummy2 is: #{config.inspect}" }
    @conf = config[:conf] + "_"
  end
end

class STdummy3 < STdummy2
  def configure( config )
    @data_cache = false
  end

  def get_entry( id, field )
    return field.to_s
  end
end