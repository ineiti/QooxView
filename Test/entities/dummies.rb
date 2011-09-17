class Dummies < Entities
  def setup_data
    @default_type = :STdummy1
    add_new_storage :STdummy2, :conf => "hello"
    
    value_str :name
    value_str_STdummy2 :phone, :length => 20
    value_list_array_STdummy2 :address, "[]", :size => 40
    
    value_int_STdummy2 :dummy_id, :chars => 30
    
    value_str_STdummy3 :no_cache
  end
end

class Dummy < Entity
  def get_storage
    @proxy.storage
  end
  
  def field_args( field )
    @proxy.field_args( field )
  end
end