require 'test/unit'
require 'benchmark'

class TC_Migration < Test::Unit::TestCase
  def setup
    Entities.delete_all_data
    @inv1 = Entities.Inventories.create( :date => "121201", :name => "comp 01" )
    @inv2 = Entities.Inventories.create( :date => "121202", :name => "comp 02" )
    @inv3 = Entities.Inventories.create( :date => "121203", :name => "comp 03" )
    Entities.save_all
  end

  def teardown
  end
  
  def test_normal
    assert_equal "121201", @inv1.date
  end
  
  def test_init
    eval( '
    class Inventories < Entities
      def setup_data
        value_date :date
        value_str :name
        value_str :typ
      end
  
      def migration_1( inv )
        dputs(0){"Adjusting inv #{inv.inspect}"}
        inv.typ = inv.name.split[0]
      end
    end ')
    Entities.load_all
    
    assert_equal "comp", @inv1.typ
  end

end