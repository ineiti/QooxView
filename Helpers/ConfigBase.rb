# To change this template, choose Tools | Templates
# and open the template in the editor.

class ConfigBases < Entities
  attr_reader :functions
  
  def setup_data
    value_list :functions, "ConfigBases.list_functions"
    
    respond_to? :add_config and add_config
    
    return true
  end
  
  def functions
    @@functions
  end
  
  def functions_base
    @@functions_base
  end
  
  def functions_conflict
    @@functions_conflict
  end
  
  def list_functions
    self.list_functions
  end
  
  def self.singleton
    if search_all.length > 0
      dputs(5){"Returning first occurence #{self.search_all.inspect}"}
      self.search_all[0]
    else
      dputs(5){"Creating instance"}
      self.create({:functions => []})
    end
  end

  def self.list_functions
    index = 0
    @@functions.collect{|f|
      index += 1
      [ index, f.to_sym ]
    }
  end  
end


class ConfigBase < Entity
  def to_hash
    super.merge( :functions => get_functions_numeric )
  end

  def get_functions
    functions.to_sym
  end
  
  def get_functions_numeric
    functions.collect{|f|
      @proxy.functions.index( f.to_sym ) + 1
    }
  end
  
  def self.get_functions
    ConfigBases.singleton.get_functions
  end
  
  def self.get_functions_numeric
    ConfigBases.singleton.get_functions_numeric
  end
  
  def self.store( c )
    if c.has_key? :functions
      funcs = c[:functions]
      ddputs(4){"Storing functions: #{funcs.inspect}"}
      if funcs.index{|i| i.to_i.to_s == i.to_s }
        dputs(3){"Converting numeric to names"}
        funcs = funcs.collect{|d|
          ConfigBases.functions[d-1].to_sym
        }
      else
        funcs.to_sym!
      end
      funcs.each{|f|
        ConfigBases.functions_base.each{|k,v| 
          if v.index( f )
            dputs(2){"Adding #{k.inspect} to #{f}"}
            funcs.push k.to_sym
          end
        }
      }
      funcs.flatten!
      ConfigBases.functions_conflict.each{|f|
        ddputs(4){"Testing conflict of #{f}"}
        count = 0
        f.each{|g|
          funcs.index( g ) and count += 1
          ddputs(4){"Count is #{count} for #{g}"}
          if count > 1
            ddputs(4){"Deleting #{g}"}
            funcs.delete( g )
          end
        }
      }
      c[:functions] = funcs
    end
    ddputs(4){"Storing #{c.inspect}"}
    ConfigBases.singleton.data_set_hash( c )
    View.update_configured_all
  end

  def self.method_missing( m, *args )
    ConfigBases.singleton.send( m, args )
  end
  
  def self.respond_to?( cmd )
    ConfigBases.singleton.respond_to?( cmd )
  end
end