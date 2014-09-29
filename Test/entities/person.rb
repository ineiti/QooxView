class Persons < Entities
  attr_reader :longtransfer_size

  def setup_data
    value_block :block_one
    value_str :first_name
    value_str :pass

    value_block :login
    value_str :login_name
    value_str :password_plain
    
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
    @longtransfer_size = 0
  end

  def icc_adduser( tr )
    ddputs(2){"Data is #{tr._data}"}
    Persons.create( tr._data )
  end

  def icc_longtransfer( tr )
    @longtransfer_size = tr._data.size
    ddputs(2){"Received #{@longtransfer_size} bytes"}
  end

  def get_longtransfer_bytes
    @longtransfer_size
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

  def check_pass( p )
    p == password_plain
  end
end
