class Courses < Entities
  attr_accessor :static

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
    value_entity_Persons_all :teacher, :drop, :first_name, proc { |p| p.credit and p.credit > 1000 }
    value_entity_Persons_empty_all :assistant, :drop, :first_name
    value_list_entity_persons :students, :login_name

    ConfigBases.add_observer(self)
  end

  def update(action, value, old)
    if action == :function_add
      Courses.search_all_.each{|c| c.tel = c.tel.to_s + '1'}
    end
  end
end
