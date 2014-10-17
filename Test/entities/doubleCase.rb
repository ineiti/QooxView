class DoubleCases < Entities
  def setup_data
    value_str :name
  end
end

class Doubles < Entities
  def setup_data
    value_str :name
    value_entity_doubleCase :dc
  end
end