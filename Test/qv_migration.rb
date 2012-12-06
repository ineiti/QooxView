require 'test/unit'
require 'benchmark'

class TC_Migration < Test::Unit::TestCase
  def setup
    Entities.delete_all_data
    @pers = Entities.Persons.create( :login_name => "test" )
    @inv1 = Entities.Inventories.create( :date => "121201", :iname => "comp 01" )
    @inv2 = Entities.Inventories.create( :date => "121202", :iname => "comp 02" )
    @inv3 = Entities.Inventories.create( :date => "121203", :iname => "comp 03" )
    Entities.save_all
  end

  def teardown
  end
  
  def test_normal
    assert_equal "121201", @inv1.date
  end
  
  def test_init
    Inventories.class_eval( '
      def setup_data
        value_date :date
        value_str :iname
        value_str :typ
      end
  
      def migration_1( inv )
        dputs(0){"Adjusting inv #{inv.inspect}"}
        inv.typ = inv.iname.split[0]
      end

      RPCQooxdooService.add_new_service( Inventories,
        "Entities.Inventories" )
      ')
    
    assert_equal "comp", Inventories.find_by_date("121201").typ
    
    Inventories.class_eval( '
      def migration_2( inv )
        dputs(0){"Adjusting inv #{inv.inspect}"}
        inv.typ = inv.date
      end

      def migration_3( inv )
        dputs(0){"Adjusting inv #{inv.inspect}"}
        inv.iname = inv.typ + "-"
      end

      RPCQooxdooService.add_new_service( Inventories,
        "Entities.Inventories" )
      ')
    assert_equal "121201-", Inventories.find_by_date("121201").iname
  end

end