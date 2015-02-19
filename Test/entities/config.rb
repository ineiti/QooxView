require 'Helpers/ConfigBase'

class ConfigBases < Entities
  def add_config
    @@functions = %w( take over world now or never linux on desktop ).to_sym
    @@functions_base = {:take => [:now, :never], :linux => [:now]}
    @@functions_conflict = [[:now, :or]]

    value_list :value, "%w( one two three )"
    value_int :integer
  end
end

class ConfigBase < Entity
  def setup_defaults
    self.integer ||= 0
  end

  def update(action, value_new, value_old = nil)
    dputs(3){"Action #{action.inspect} changed to #{value_new.inspect} from "+
        "#{value_old.inspect}"}
    case action
      when :function_add
        if value_new.index :now
          self.integer += 1
        end
      when :function_del
        if value_new.index :now
          self.integer += 3
        end
    end
  end
end