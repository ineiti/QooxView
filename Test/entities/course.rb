class Courses < Entities
  def setup_data
    value_block :first_name
    value_str :first_name
    value_date :start
    value_date :end
    
    value_block :address
    value_str :street
    value_str :plz
    value_str :tel
    
    value_block :names
    value_entity_Persons :teacher, :drop, :first_name, proc { |p| p.credit > 1000 }
  end
end

class Course < Entity
end