require 'test/unit'
require 'benchmark'

class TC_Migration < Test::Unit::TestCase
  def setup
    Entities.delete_all_data
    CVSInventories.class_eval( '
      def setup_data
        value_date :date
        value_str :iname
      end

      (1..3).each{|v|
        begin
          remove_method "migration_#{v}".to_sym
        rescue NameError
        end
        begin
          remove_method "migration_#{v}_raw".to_sym
        rescue NameError
        end
      }

      RPCQooxdooService.add_new_service( CVSInventories,
        "Entities.CVSInventories" )
      ')
    @pers = Entities.Persons.create( :login_name => 'test')
    @inv1 = Entities.CVSInventories.create( :date => '121201', :iname => 'comp 01')
    @inv2 = Entities.CVSInventories.create( :date => '121202', :iname => 'comp 02')
    @inv3 = Entities.CVSInventories.create( :date => '121203', :iname => 'comp 03')
    Entities.save_all
  end

  def teardown
    dputs(1){ 'Tearing down' }
  end
  
  def test_cvs_normal
    assert_equal '121201', @inv1.date
  end
  
  def test_cvs_init
    assert_equal 'comp 01', CVSInventories.match_by_date('121201').iname

    dputs(5){ 'Before class_eval' }
    CVSInventories.class_eval( '
      def setup_data
        dputs(1){"new inventories"}
        value_date :date
        value_str :iname
        value_str :typ
      end
  
      def migration_1( inv )
        dputs(1){"Adjusting inv #{inv.inspect}"}
        inv.typ = inv.iname.split[0]
      end

      dputs(1){"Adding to RPC"}
      RPCQooxdooService.add_new_service( CVSInventories,
        "Entities.CVSInventories" )
      ')
    
    assert_equal 'comp', CVSInventories.match_by_date('121201').typ
    
    CVSInventories.class_eval( '
      def migration_2( inv )
        dputs(1){"Adjusting inv #{inv.inspect}"}
        inv.typ = inv.date
      end

      def migration_3( inv )
        dputs(1){"Adjusting inv #{inv.inspect}"}
        inv.iname = inv.typ + "-"
      end

      RPCQooxdooService.add_new_service( CVSInventories,
        "Entities.CVSInventories" )
      ')
    assert_equal '121201-', CVSInventories.match_by_date('121201').iname
  end
  
  # Also tests deletion - this is kind of a bug that it works, because
  # the Entities.load function should not load fields that are not
  # defined - probably only works for CVS...
  def test_cvs_rename
    CVSInventories.class_eval( '
      def setup_data
        value_date :date
        value_str :i_name
      end
  
      def migration_1_raw( inv )
        dputs(1){"rename: Adjusting inv #{inv.inspect}"}
        inv._i_name = inv._iname
      end

      RPCQooxdooService.add_new_service( CVSInventories,
        "Entities.CVSInventories" )
      ')
    
    assert_equal 'comp 01', CVSInventories.match_by_date('121201').i_name
  end
  
  def test_raw
    CVSInventories.class_eval( '
      def setup_data
        value_date :date
        value_str :i_name
      end
  
      def migration_1_raw( inv )
        dputs(1){"renaming raw: Adjusting inv #{inv.inspect}"}
        inv[:i_name] = inv[:iname]
        dputs(1){"Is now #{inv.inspect}"}
      end

      RPCQooxdooService.add_new_service( CVSInventories,
        "Entities.CVSInventories" )
      ')    

    cvs = CVSInventories.match_by_date('121201')
    assert_equal 'comp 01', cvs.i_name
  end

end