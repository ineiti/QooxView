require 'Helpers/ConfigBase'

class ConfigBases < Entities
  @@functions = %w( take over world now or never linux on desktop ).to_sym
  @@functions_base = { :take => [:now, :never], :linux => [ :now ] }
  @@functions_conflict = [ [:now, :or ] ]
  
  def add_config
    value_list :value, "%w( one two three )"
  end
end
