class Movements < Entities
  def setup_data
    @default_type = :SQLite

    value_str :desc
    value_int :money
  end
end

class Accounts < Entities
  def setup_data
    @default_type = :SQLite
    
    value_str :name
    value_int :multiplier
  end
end
