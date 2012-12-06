class Inventories < Entities
  def setup_data
    value_date :date
    value_str :name
    value_str :type
  end
  
  def migration_1( inv )
    
  end
end