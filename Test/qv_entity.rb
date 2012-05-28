require 'test/unit'
require 'benchmark'

class TC_Entity < Test::Unit::TestCase
  def setup
    Entities.delete_all_data
    @admin = Entities.Persons.create( :first_name => "admin", :pass => "super123",
    :address => "cdlf 24", :credit => 10000 )
    Entities.Courses.create( :first_name => "base_1010", :start => "1.10.2010")
    @base_1011 = Entities.Courses.create( :first_name => "base_1011", :start => "1.11.2010",
    :teacher => @admin )
    @dummies_one = Entities.Dummies.create( :first_name => "one", :phone => "111",
    :no_cache => "123" )
  end

  def teardown
  end

  def test_create_with_new_id
    student_id = 2
    Entities.Persons.create( :person_id => student_id, :first_name => "student" )
    guest_id = Entities.Persons.new_id[:person_id]
    guest = Entities.Persons.create( :person_id => guest_id, :first_name => "guest",
    :credit => 1000 )
    assert_equal guest_id, guest.person_id
    assert_equal "guest", guest.first_name
    assert_equal 1000, guest.credit

    guest = Entities.Persons.find_by_person_id( guest_id )
    student = Entities.Persons.find_by_person_id( student_id )
    assert_equal "guest", guest.first_name
    assert_equal "student", student.first_name
  end

  def test_create_with_double_id
    admin = Entities.Persons.find_by_first_name( "admin")
    student = Entities.Persons.create( :person_id => admin.person_id, :first_name => "duplicate" )
    assert_equal nil, student
  end

  def test_find_admin
    admin = Entities.Persons.find_by_first_name( "admin" )
    assert_nothing_raised do
      assert_equal 0, admin.person_id
      assert_equal 'super123', admin.pass
      assert_equal 'cdlf 24', admin.address
      assert_equal 10000, admin.credit
    end
  end

  def test_save_load
    Entities.save_all
    Entities.delete_all_data( true )
    Entities.load_all
    test_find_admin
  end

  def test_logactions
    admin = Entities.Persons.find_by_first_name( "admin" )
    admin.set_entry( :credit, 100 )
    admin.set_entry( :pass, "hello123" )
    # Take out the date_stamps, as they change all the time...
    log_list = Entities.LogActions.log_list.each{|l| l.delete( :date_stamp )}
    assert_equal [
=begin
    {:logaction_id=>0, :data_field=>:no_cache, :undo_function=>:undo_set_entry,
      :data_value=>"123", :data_old=>"\"no_cache\"", 
      :data_class=>Dummy, :data_class_id=>0, :msg=>nil},
    {:logaction_id=>1, :data_field=>:dummy_id, :undo_function=>:undo_set_entry,
      :data_value=>0, :data_old=>"\"dummy_id\"", :data_class=>Dummy,
      :data_class_id=>0, :msg=>nil},
=end
    {:logaction_id=>0, :undo_function=>:undo_set_entry,
      :data_field=>:credit, :data_value=>100, :data_old=>"10000", 
      :data_class => "Person",
      :data_class_id=>0 },
    {:logaction_id=>1, :undo_function=>:undo_set_entry,
      :data_field=>:pass, :data_value=>"hello123",
      :data_old=>"\"super123\"", :data_class => "Person",
      :data_class_id=>0} ],
    log_list
  end

  def test_logactions_filter
    admin = Entities.Persons.find_by_first_name( "admin" )
    admin.set_entry( :credit, 100 )
    admin.set_entry( :pass, "hello123" )
    course = Entities.Courses.find_by_first_name( "base_1010" )
    course.set_entry( :end, "1.3.2011" )

    log_list = Entities.LogActions.log_list
    assert_equal 3, log_list.size

    log_list = Entities.LogActions.log_list( { :data_field => :credit } )
    assert_equal 1, log_list.size

    log_list = Entities.LogActions.log_list( { :data_class => Person } )
    assert_equal 2, log_list.size

    log_list = Entities.LogActions.log_list( { :data_class => Person, :data_field => :credit } )
    assert_equal 1, log_list.size
  end

  def test_logactions_filter_multi
    admin = Entities.Persons.find_by_first_name( "admin" )
    admin.set_entry( :credit, 100, "charger:linus" )
    admin.set_entry( :credit, 200, "charger:viviane" )
    admin.set_entry( :credit, 300, "charger:linuss" )
    admin.set_entry( :pass, "hello123" )
    course = Entities.Courses.find_by_first_name( "base_1010" )
    course.set_entry( :end, "1.3.2011" )

    log_list = Entities.LogActions.log_list
    assert_equal 5, log_list.size

    log_list = Entities.LogActions.log_list( { :data_field => :credit } )
    assert_equal 3, log_list.size

    log_list = Entities.LogActions.log_list( { :data_field => :credit, :msg => "^charger:linus$" } )
    assert_equal 1, log_list.size

    assert_equal 4, Entities.Persons.log_list.size
    assert_equal 1, Entities.Persons.log_list( { :msg => "^charger:linus$" } ).size
  end

  def test_getfields
    assert_equal %w( course_id first_name start end street plz teacher tel ).sort.to_s,
    Entities.Courses.get_field_names.sortk.to_s
  end

  def test_list
    assert_equal %w( base_1010 base_1011 ),
    Entities.Courses.list_first_name
  end

  def test_value_add_new
    assert_equal %w( session_id address credit first_name pass person_id l_a l_c l_d l_s l ).sort.to_s,
    Entities.Persons.get_field_names.sortk.to_s

    assert_equal ["list", :l_a, "l_a", {:list_type=>"array", :list_values=>[]}],
    Entities.Persons.blocks[:lists][0].to_a
    assert_equal ["list", :l_c, "l_c", {:list_type=>"choice", :list_values=>[]}],
    Entities.Persons.blocks[:lists][1].to_a
    assert_equal ["list", :l_d, "l_d", {:list_type=>"drop", :list_values=>[]}],
    Entities.Persons.blocks[:lists][2].to_a
    assert_equal ["list", :l_s, "l_s", {:list_type=>"single", :list_values=>[]}],
    Entities.Persons.blocks[:lists][3].to_a
    assert_equal ["list", :l, "l", {:list_values=>[]}],
    Entities.Persons.blocks[:lists][4].to_a
  end

  def test_cache_data
    assert_equal "one", @dummies_one.first_name
    assert_equal "111", @dummies_one.phone
    assert_equal "no_cache", @dummies_one.no_cache
  end

  def test_data_get
    assert_equal [ "admin", "super123" ], @admin.data_get( %w( first_name pass ) )
  end
  
  def test_value_entity
    val = Entities.Courses.get_value( :teacher )
    assert_equal "entity", val.dtype
    assert_equal "Persons", val.entity_class
    assert_equal Entities.Persons, val.eclass
    val_hash = @base_1011.to_hash( true )
    assert_equal [0], val_hash[:teacher]
    assert_equal "super123", @base_1011.teacher.pass
    @admin.pass = "super321"
    assert_equal "super321", @base_1011.teacher.pass
    @base_1011.teacher.pass = "super111" 
    assert_equal "super111", @base_1011.teacher.pass
    assert_equal "super111", @admin.pass
  end
end