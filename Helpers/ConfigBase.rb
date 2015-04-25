# To change this template, choose Tools | Templates
# and open the template in the editor.
require 'observer'

class ConfigBases < Entities
  include Observable

  def setup_data
    value_block :wide
    value_list :functions, 'ConfigBases.list_functions'
    value_str :dputs_logfile
    value_text :welcome_text

    value_block :narrow
    value_str :locale_force
    value_str :version_local
    value_str :use_printing
    value_int :debug_lvl
    value_list_drop :dputs_show_time, '%w(false min sec)'
    value_list_drop :dputs_silent, '%w(false true)'
    value_int :dputs_terminal_width
    value_int :block_size
    value_int :max_upload_size

    @@functions = []
    @@functions_base = {}
    @@functions_conflict = []

    respond_to? :add_config and add_config

    return true
  end

  def migration_1(c)
    c._debug_lvl = 2
    c._locale_force = 'fr'
    c._version_local = 'orig'
    c._welcome_text = 'Welcome to Profeda'
    # Values for slow, buggy lines. For a good transfer-rate, choose 16x more
    c._block_size = 4096
    c._max_upload_size = 65_536
    c.diploma_dir = 'Diplomas'
    c.exam_dir = 'Exams'
    c.presence_sheet = 'presence_sheet.ods'
    c.presence_sheet_small = 'presence_sheet_small.ods'
    c.dputs_logfile = '/var/log/gestion/events.log'
    c.dputs_show_time = %w(min)
    c.dputs_silent = %w(false)
    c.dputs_terminal_width = 160

    dputs(3) { "Migrating out: #{c.inspect}" }
  end

  def call_changed(action, value, old)
    ConfigBases.singleton.update(action, value, old)
    changed
    notify_observers(action, value, old)
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

  def init
  end

  def self.singleton
    first or
        self.create({:functions => [], :locale_force => nil, :welcome_msg => ''})
  end

  def self.list_functions
    index = 0
    @@functions.collect { |f|
      index += 1
      [index, f.to_sym]
    }
  end
end


class ConfigBase < Entity
  def setup_instance
    dputs(4) { "Setting up ConfigBase with debug_lvl = #{debug_lvl}" }
    if !Object.const_defined? :DEBUG_LVL
      self.debug_lvl = debug_lvl
    end
    DPuts.silent = dputs_silent == %w(true)
    DPuts.show_time = (dputs_show_time || %w(min)).first
    DPuts.terminal_width = (dputs_terminal_width || 160).to_i
    is_loading { setup_defaults }
  end

  def setup_defaults
  end

  def is_loading
    oldloading = @loading
    @loading = true
    yield
    @loading = oldloading
  end

  def data_set(field, value)
    old = data_get(field)
    ret = super(field, value)
    if !@loading
      return if old == value
      dputs(3) { "Updating #{field} to #{value.inspect}, #{old.inspect}" }
      if field == :functions
        if (del = old - value).length > 0
          @proxy.call_changed(:function_del, del, nil)
        end
        if (add = value - old).length > 0
          @proxy.call_changed(:function_add, add, nil)
        end
      else
        @proxy.call_changed(field, value, old)
      end
    end
    ret
  end

  def update(action, value, old = nil)
    dputs(3) { "No action #{action.inspect} changed to #{value.inspect} from #{old.inspect}" }
    #super(action, value, old)
  end

  def save_block_to_object(block, obj)
    dputs(3) { "Pushing block #{block} to object #{obj.name}" }
    ConfigBases.get_block_fields(block).each { |f|
      value = data_get(f)
      dputs(3) { "Setting #{f} in #{block} to #{value}" }
      obj.send("#{f}=", value)
    }
  end

  def debug_lvl=(lvl)
    dputs(4) { "Setting debug-lvl to #{lvl}" }
    data_set(:_debug_lvl, lvl.to_i)
    Object.const_defined?(:DEBUG_LVL) and Object.send(:remove_const, :DEBUG_LVL)
    Object.const_set(:DEBUG_LVL, lvl.to_i)
  end

  def dputs_show_time=(t)
    DPuts.show_time = (self._dputs_show_time = t).first
  end

  def dputs_silent=(s)
    DPuts.silent = (self._dputs_silent = s) == %w(true)
  end

  def dputs_terminal_width=(w)
    DPuts.terminal_width = (self._dputs_terminal_width = w).to_i
  end

  def to_hash
    super.merge(:functions => get_functions_numeric)
  end

  def get_functions
    functions.to_sym
  end

  def get_functions_numeric
    functions.collect { |f|
      @proxy.functions.index(f.to_sym) + 1
    }
  end

  def self.get_functions
    ConfigBases.singleton.get_functions
  end

  def self.get_functions_numeric
    ConfigBases.singleton.get_functions_numeric
  end

  def self.store(c = {})
    #dputs_func
    if c.has_key? :functions
      funcs = c._functions
      dputs(4) { "Storing functions: #{funcs.inspect}" }
      if funcs.index { |i| i.to_s.to_i.to_s == i.to_s }
        dputs(3) { 'Converting numeric to names' }
        funcs = funcs.collect { |d|
          ConfigBases.functions[d-1].to_sym
        }
      else
        funcs.to_sym!
      end
      funcs.each { |f|
        ConfigBases.functions_base.each { |k, v|
          if v.index(f)
            dputs(2) { "Adding #{k.inspect} to #{f}" }
            funcs.push k.to_sym
          end
        }
      }
      funcs.flatten!
      ConfigBases.functions_conflict.each { |f|
        dputs(4) { "Testing conflict of #{f}" }
        list = f.collect { |g|
          funcs.index(g)
        }.select { |l| l }.sort
        dputs(4) { "List is #{list.inspect}" }
        if list.length > 1
          list.pop
          dputs(4) { "Deleting #{list.inspect}" }
          list.each { |l| funcs.delete_at(l) }
        end
      }
      c[:functions] = funcs
    end
    dputs(4) { "Storing #{c.inspect}" }
    ConfigBases.singleton.data_set_hash(c)
    ConfigBase.setup_defaults
    View.update_configured_all
  end

  def self.method_missing(m, *args)
    dputs(4) { "#{m} - #{args.inspect} - #{ConfigBases.singleton.inspect}" }
    if args.length > 0
      ConfigBases.singleton.send(m, *args)
    else
      ConfigBases.singleton.send(m)
    end
  end

  def self.respond_to?(cmd)
    ConfigBases.singleton.respond_to?(cmd)
  end

  def self.has_function?(func)
    ConfigBase.get_functions.index(func) != nil
  end

  def self.set_functions(func)
    self.store({:functions => func})
  end

  def self.add_function(func)
    self.store({:functions => self.get_functions.push(func)})
  end

  def self.del_function(func)
    self.store({:functions => self.get_functions.reject { |f| f == func }})
  end
end
