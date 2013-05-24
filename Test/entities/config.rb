require 'Helpers/ConfigBase'

class ConfigBases < Entities
  @@functions = %w( take over world now or never ).to_sym
  @@functions_base = { :take => [:now, :never]}
  @@functions_conflict = [ [:now, :or ] ]
end
