require 'Helpers/ConfigBase'

class ConfigBases < Entities
  @@functions = %w( take over world now or never ).to_sym
  @@functions_base = { :take => [:now, :never]}
end
