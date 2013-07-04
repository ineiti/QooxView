class Persons < Entities
  def setup_data
    value_block :block_one
    value_str :first_name
    value_str :pass
    
#    value_block :array
#    value_array :a, :String
    
    value_block :lists
    value_list_array :l_a, "[]"
    value_list_choice :l_c, "[]"
    value_list_drop :l_d, "[]"
    value_list_single :l_s, "[]"
    value_list :l, "[]"

    value_block :block_two
    value_str :address
    value_int :credit
    
    value_block :rest
    value_int :session_id
    value_list :permissions
    
    value_block :override
    value_int :value1
    value_int :value2
    
#    value_block :add_new
#    value_bogus :name_bogus
#    value_africompta_bogus :name_2, "account_name"
  end
end

class Person < Entity
  def value1
    _value1 / 2
  end

  def value1=( v )
    self._value1 = v
    self.value2 = 2 * v
  end
end
