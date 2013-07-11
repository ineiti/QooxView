# To change this template, choose Tools | Templates
# and open the template in the editor.

class ConfigBases < Entities
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
  
  def self.store( c = {} )
    if c.has_key? :functions
      funcs = c[:functions]
      dputs(4){"Storing functions: #{funcs.inspect}"}
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
        dputs(4){"Testing conflict of #{f}"}
        list = f.collect{|g|
          funcs.index( g )
        }.select{|l| l }.sort
        dputs(4){"List is #{list.inspect}"}
        if list.length > 1
          list.pop
          dputs(4){"Deleting #{list.inspect}"}
          list.each{|l| funcs.delete_at( l ) }
        end
      }
      c[:functions] = funcs
    end
    dputs(4){"Storing #{c.inspect}"}
    ConfigBases.singleton.data_set_hash( c )
    View.update_configured_all
  end

  def self.method_missing( m, *args )
    dputs(4){"#{m} - #{args.inspect}"}
    ConfigBases.singleton.send( m, args )
  end
  
  def self.respond_to?( cmd )
    ConfigBases.singleton.respond_to?( cmd )
  end
  
  def self.has_function?( func )
    ConfigBase.get_functions.index( func ) != nil
  end
  
  def self.set_functions( func )
    self.store( {:functions => func} )
  end
  
  def self.add_function( func )
    self.store( {:functions => self.get_functions.push( func ) })
  end
  
  def self.del_function( func )
    self.store( {:functions => self.get_functions.reject{|f| f == func} })
  end
end