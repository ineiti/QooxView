require 'test/unit'

class TC_SType < Test::Unit::TestCase
  def setup
    Entities.delete_all_data()
    @one = Entities.Dummies.create( :first_name => "one", :phone => "111" )
    @two = Entities.Dummies.create( :first_name => "two", :phone => "222" )
  end
  
  def teardown
  end
  
  def test_type    
    assert_equal "111", @one.phone
    assert_equal "222", @two.phone
    
    assert_equal [ :dummy_id, :first_name ], @one.get_storage[:STdummy1].fields.keys.sortk
    assert_equal [ :address, :dummy_id, :phone ], @one.get_storage[:STdummy2].fields.keys.sortk
    
    assert_equal [ :address, :dummy_id, :first_name, :no_cache, :phone ],
      Entities.Dummies.get_field_names.sortk
  end
  
  def test_config
    assert_equal "passit", @one.get_storage[:STdummy1].conf
    assert_equal "hello_", @two.get_storage[:STdummy2].conf
    
    assert_equal 20, @two.field_args( :phone )[:length]
  end
  
  # Look whether a new data-set get's the data_create called
  def test_create
    
  end
  
  def test_all
    assert @one.get_storage[:STdummy1].has_field( :dummy_id )
    assert @one.get_storage[:STdummy2].has_field( :dummy_id )
    assert @one.get_storage[:STdummy3].has_field( :dummy_id )
  end
end