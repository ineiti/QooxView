require 'test/unit'
require 'benchmark'

class TC_SQLite < Test::Unit::TestCase
  def setup
    Entities.delete_all_data
    @m1 = Entities.Movements.create( :desc => "salaire", :money => 100 )
    @m2 = Entities.Movements.create( :desc => "pain", :money => 200 )
  end

  def teardown
  end

  def test_create
    one = Entities.Movements.find_by_desc( "salaire" )
    assert_not_nil one
    two = Entities.Movements.find_by_desc( "pain" )
    assert_not_nil two
    assert_equal 100, one.money
    assert_equal 200, two.money
  end
  
  def test_load
    Entities.Movements.load
    test_create
  end
  
  def tes_speed
    Entities.delete_all_data
    dputs 0, "Creation of 1000 entities: "
    dputs 0, Benchmark.measure{
      (1..1000).each{|e|
        Entities.Movements.create( :desc => "test", :money => e)
      }
    }
    dputs 0, "Loading 1000 entities: "
    dputs 0, Benchmark.measure{ Entities.Movements.load }
    dputs 0, "Searching in 1000 entities: "
    dputs 0, Benchmark.measure{ Entities.Movements.find_by_money(500)}
  end
  
  def test_set_value
    Entities.Movements.load
    @m1.money = 300
    @m2.money = 500
    Entities.Movements.load
    one = Entities.Movements.find_by_desc( "salaire" )
    two = Entities.Movements.find_by_desc( "pain" )
    assert_equal 300, one.money
    assert_equal 500, two.money
    assert_equal 300, @m1.money
    assert_equal 500, @m2.money
  end
end