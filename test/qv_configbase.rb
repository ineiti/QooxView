require 'test/unit'

class TC_ConfigBase < Test::Unit::TestCase
  def setup
    Entities.delete_all_data
  end
  
  def teardown
  end
  
  def test_init
    assert_equal [[1,:take],[2,:over],[3,:world],
      [4,:now],[5,:or],[6,:never],
      [7, :linux], [8, :on], [9, :desktop]], ConfigBases.list_functions
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
    assert_equal [:now, :take, :linux], ConfigBase.get_functions

    ConfigBase.store( :functions => [:take])
    assert_equal [:take], ConfigBase.get_functions
  end
  
  def test_conflict
    ConfigBase.store( :functions => [:now, :or])
    assert_equal [:or, :take, :linux], ConfigBase.get_functions
  end
  
  def test_hasfunction
    ConfigBase.store( :functions => [:take, :over ])
    assert ConfigBase.has_function?(:take)
    assert ConfigBase.has_function?(:over)
    assert ! ConfigBase.has_function?(:or)
  end
  
  def test_add_set_function
    ConfigBase.set_functions([:now, :or])
    assert_equal [:or, :take, :linux], ConfigBase.get_functions
    
    ConfigBase.add_function( :over )
    assert ConfigBase.has_function? :over
  end
  
  def test_add_multiple
    ConfigBase.add_function :now
    assert ConfigBase.has_function? :now
    ConfigBase.add_function :or
    assert ConfigBase.has_function? :or
    assert ! ConfigBase.has_function?( :now )
    ConfigBase.add_function :now
    assert ConfigBase.has_function? :now
    assert ! ConfigBase.has_function?( :or )
  end

  def test_value
    ConfigBase.integer = 10
    assert_equal 10, ConfigBase.integer
  end

  def test_change_value
    ConfigBase.integer = 10
    assert_equal 10, ConfigBase.integer
    ConfigBase.add_function :now
    assert_equal 11, ConfigBase.integer
    ConfigBase.add_function :now
    assert_equal 11, ConfigBase.integer
    ConfigBase.del_function :now
    assert_equal 14, ConfigBase.integer

    c = Courses.create(name: 'test')
    assert_equal nil, c.tel
    ConfigBase.add_function :now
    assert_equal '1', c.tel

    Entities.delete_all_data
    c = Courses.create(name: 'test')
    assert_equal nil, c.tel
    ConfigBase.add_function :now
    assert_equal '1', c.tel
  end
end