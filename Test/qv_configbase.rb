require 'test/unit'

class TC_Entity < Test::Unit::TestCase
  def setup
  end
  
  def teardown
  end
  
  def test_init
    assert_equal [[1,:take],[2,:over],[3,:world],
    [4,:now],[5,:or],[6,:never]], ConfigBases.list_functions
  end
  
  def test_save
    ConfigBase.store( :functions => [1,2] )
    assert_equal [:take,:over], ConfigBase.get_functions

    ConfigBase.store( :functions => [1] )
    assert_equal [:take], ConfigBase.get_functions
  end

  def test_save_names
    ConfigBase.store( :functions => [:take, :over] )
    assert_equal [:take,:over], ConfigBase.get_functions

    ConfigBase.store( :functions => [:take] )
    assert_equal [:take], ConfigBase.get_functions
  end
  
  def test_base
    ConfigBase.store( :functions => [:now])
    assert_equal [:now, :take], ConfigBase.get_functions

    ConfigBase.store( :functions => [:take])
    assert_equal [:take], ConfigBase.get_functions
  end
  
  def test_conflict
    ConfigBase.store( :functions => [:now, :or])
    assert_equal [:now, :take], ConfigBase.get_functions
  end
end