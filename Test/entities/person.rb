class Persons < Entities
  def setup_data
    value_block :block_one
    value_str :name
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
    
#    value_block :add_new
#    value_bogus :name_bogus
#    value_africompta_bogus :name_2, "account_name"
  end
end

class Person < Entity
end
