require 'Helpers/ConfigBase'

class ConfigBases < Entities
  def add_config
    @@functions = %w( take over world now or never linux on desktop ).to_sym
    @@functions_base = { :take => [:now, :never], :linux => [ :now ] }
    @@functions_conflict = [ [:now, :or ] ]
  
    value_list :value, "%w( one two three )"
    value_int :integer
  end
end
