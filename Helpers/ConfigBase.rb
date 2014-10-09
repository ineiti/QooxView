# To change this template, choose Tools | Templates
# and open the template in the editor.

class ConfigBases < Entities
  def setup_data
    value_block :wide
    value_list :functions, "ConfigBases.list_functions"
    value_text :welcome_text
    
    value_block :narrow
    value_str :locale_force
    value_int :debug_lvl
    value_str :version_local
    value_bool :use_printing

    @@functions = []
    @@functions_base = {}
    @@functions_conflict = []
    
    respond_to? :add_config and add_config
    
    return true
  end
  
  def migration_1( c )
    c._debug_lvl = DEBUG_LVL
    c._locale_force = get_config( nil, :locale_force )
    c._version_local = get_config( "orig", :version_local )
    c._welcome_text = get_config( false, :welcome_text )
    dputs(3){"Migrating out: #{c.inspect}"}
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
    first or
      self.create({:functions => [], :locale_force => nil, :welcome_msg => "" })
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
      if funcs.index{|i| i.to_s.to_i.to_s == i.to_s }
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
    dputs(4){"#{m} - #{args.inspect} - #{ConfigBases.singleton.inspect}"}
    if args.length > 0
      ConfigBases.singleton.send( m, *args )
    else
      ConfigBases.singleton.send( m )
    end
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

class ConfigBase < Entity
  def setup_instance
    dputs(4){"Setting up ConfigBase with debug_lvl = #{debug_lvl}"}
    if DEBUG_LVL == 0.5
      # Special marked DEBUG_LVL which means there is only a definition in here
      self.debug_lvl = debug_lvl
    end
  end

  def debug_lvl=( lvl )
    dputs(4){"Setting debug-lvl to #{lvl}"}
    data_set( :_debug_lvl, lvl.to_i )
    Object.send( :remove_const, :DEBUG_LVL )
    Object.const_set( :DEBUG_LVL, lvl.to_i )
  end
end
