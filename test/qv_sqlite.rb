require 'test/unit'
require 'benchmark'

class TC_SQLite < Test::Unit::TestCase
  def setup
    Entities.delete_all_data
    @m1 = Entities.Movements.create( :desc => 'salaire', :money => 100 )
    @m2 = Entities.Movements.create( :desc => 'pain', :money => 200 )
    Entities.save_all
  end

  def teardown
  end

  def test_create
    one = Entities.Movements.match_by_desc('salaire')
    assert_not_nil one
    two = Entities.Movements.match_by_desc('pain')
    assert_not_nil two
    assert_equal 100, one.money
    assert_equal 200, two.money
  end
  
  def test_load
    Entities.Movements.load
    test_create
  end
  
  def test_speed
    Entities.delete_all_data
    dputs( 1 ){ 'Creation of 250 entities: ' }
    (1..4).each{|f|
      dputs( 1 ){ Benchmark.measure{
          (1..250).each{|e|
            Entities.Movements.create( :desc => 'test', :money => e)
          }
        }.to_s
      }
    }
    dputs( 1 ){ 'Loading 1000 entities: ' }
    dputs( 1 ){ Benchmark.measure{ Entities.Movements.load }.to_s }
    dputs( 1 ){ 'Searching in 1000 entities: ' }
    dputs( 1 ){ Benchmark.measure{ Entities.Movements.matches_by_desc('test')}.to_s }
    dputs( 1 ){ 'Searching test gives ' +
        "#{Entities.Movements.matches_by_desc('test').count}"}
  end
  
  def test_set_value
    Entities.Movements.load
    @m1.money = 300
    @m2.money = 500
    assert_equal 300, @m1.money
    assert_equal 500, @m2.money
    Entities.Movements.delete_all(true)
    Entities.Movements.load
    one = Entities.Movements.match_by_desc('salaire')
    two = Entities.Movements.match_by_desc('pain')
    assert_equal 100, one.money
    assert_equal 200, two.money

    one.money = 300
    Entities.Movements.save
    two.money = 500
    Entities.Movements.save
    assert_equal 300, one.money
    assert_equal 500, two.money
    Entities.Movements.load
    one = Entities.Movements.match_by_desc('salaire')
    two = Entities.Movements.match_by_desc('pain')
    assert_equal 300, one.money
    assert_equal 500, two.money
  end

  def test_rm_add
    dp 'deleting'
    assert_not_equal nil, Entities.Movements.find_by_desc('pain')
    @m2.delete
    assert_equal nil, Entities.Movements.find_by_desc('pain')
    Entities.delete_all_data(true)
    Entities.load_all
    assert_equal nil, Entities.Movements.find_by_desc('pain')
    dp 'recreating'
    @m2 = Entities.Movements.create( :desc => 'mappa', :money => 250 )
    assert_equal 250, @m2.money
  end
end