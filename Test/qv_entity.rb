require 'test/unit'
require 'benchmark'

class TC_Entity < Test::Unit::TestCase
  def setup
    dputs(2){"Deleting everything"}
    Entities.delete_all_data
    
    dputs(2){"Setting up data"}
    @admin = Entities.Persons.create( :first_name => "admin", :pass => "super123",
      :address => "cdlf 24", :credit => 10000 )
    Entities.Courses.create( :first_name => "base_1010", :start => "1.10.2010")
    @base_1011 = Entities.Courses.create( :first_name => "base_1011", :start => "1.11.2010",
      :teacher => @admin )
    @dummies_one = Entities.Dummies.create( :first_name => "one", :phone => "111",
      :no_cache => "123" )
    dputs(2){"Finished setting up data"}
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

    guest = Entities.Persons.match_by_person_id( guest_id )
    student = Entities.Persons.match_by_person_id( student_id )
    assert_equal "guest", guest.first_name
    assert_equal "student", student.first_name
  end

  def test_create_with_double_id
    admin = Entities.Persons.match_by_first_name( "admin")
    student = Entities.Persons.create( :person_id => admin.person_id, :first_name => "duplicate" )
    assert_equal nil, student
  end

  def test_find_admin
    admin = Entities.Persons.match_by_first_name( "admin" )
    assert_nothing_raised do
      assert_equal 1, admin.person_id
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
    oldlog = LogActions.logging
    LogActions.logging = true
    admin = Entities.Persons.match_by_first_name( "admin" )
    admin.data_set_log( :credit, 100 )
    admin.data_set_log( :pass, "hello123" )
    # Take out the date_stamps, as they change all the time...
    log_list = Entities.LogActions.log_list.each{|l| l.delete( :date_stamp )}
    assert_equal [
      {:logaction_id=>1, :undo_function=>:undo_set_entry,
        :data_field=>:credit, :data_value=>100, :data_old=>10000, 
        :data_class => "Person",
        :msg => nil,
        :data_class_id=>1 },
      {:logaction_id=>2, :undo_function=>:undo_set_entry,
        :data_field=>:pass, :data_value=>"hello123",
        :data_old=>"super123", :data_class => "Person",
        :msg => nil,
        :data_class_id=>1 } ],
      log_list
    LogActions.logging = oldlog
  end

  def test_logactions_filter
    oldlog = LogActions.logging
    LogActions.logging = true

    admin = Entities.Persons.match_by_first_name( "admin" )
    admin.data_set_log( :credit, 100 )
    admin.data_set_log( :pass, "hello123" )
    course = Entities.Courses.match_by_first_name( "base_1010" )
    course.data_set_log( :end, "1.3.2011" )

    log_list = Entities.LogActions.log_list
    assert_equal 3, log_list.size

    log_list = Entities.LogActions.log_list( { :data_field => :credit } )
    assert_equal 1, log_list.size

    log_list = Entities.LogActions.log_list( { :data_class => Person } )
    assert_equal 2, log_list.size

    log_list = Entities.LogActions.log_list( { :data_class => Person, :data_field => :credit } )
    assert_equal 1, log_list.size

    LogActions.logging = oldlog
  end

  def test_logactions_filter_multi
    oldlog = LogActions.logging
    LogActions.logging = true

    admin = Entities.Persons.match_by_first_name( "admin" )
    admin.data_set_log( :credit, 100, "charger:linus" )
    admin.data_set_log( :credit, 200, "charger:viviane" )
    admin.data_set_log( :credit, 300, "charger:linuss" )
    admin.data_set_log( :pass, "hello123" )
    course = Entities.Courses.match_by_first_name( "base_1010" )
    course.data_set_log( :end, "1.3.2011" )

    log_list = Entities.LogActions.log_list
    assert_equal 5, log_list.size

    log_list = Entities.LogActions.log_list( { :data_field => :credit } )
    assert_equal 3, log_list.size

    log_list = Entities.LogActions.log_list( { :data_field => :credit, :msg => "^charger:linus$" } )
    assert_equal 1, log_list.size

    assert_equal 4, Entities.Persons.log_list.size
    assert_equal 1, Entities.Persons.log_list( { :msg => "^charger:linus$" } ).size

    LogActions.logging = oldlog
  end

  def test_getfields
    assert_equal %w( assistant course_id first_name start end street plz 
      students teacher tel ).sort.to_s,
      Entities.Courses.get_field_names.sortk.to_s
  end

  def test_list
    assert_equal %w( base_1010 base_1011 ),
      Entities.Courses.list_first_name
  end

  def test_value_add_new
    assert_equal %w( session_id address credit first_name pass person_id permissions
     l_a l_c l_d l_s l value1 value2 ).sort.to_s,
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
    dputs(2){"testing cache data"}
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
    val_hash = @base_1011.to_hash
    assert_equal [1], val_hash[:teacher]
    assert_equal "super123", @base_1011.teacher.pass
    @admin.pass = "super321"
    assert_equal "super321", @base_1011.teacher.pass
    @base_1011.teacher.pass = "super111" 
    assert_equal "super111", @base_1011.teacher.pass
    assert_equal "super111", @admin.pass
  end
	
  def test_speed_persons
    require 'rubygems'
    require 'perftools'
    PerfTools::CpuProfiler.start("/tmp/profile") do
      (1..400).each{|p|
        dputs( 1 ){ "Creating person #{p}" }
        Courses.create( :first_name => "#{p}", :last_name => "#{p}" )
      }
    end
  end
  
  def test_entity_empty
    assert_equal 1, @admin.person_id
    #@base_1011.data_set_hash({:assistant => [1]})
    empty = Courses.get_value( :assistant ).parse( [0] )
    assert_equal 0, empty
  end
  
  def test_needs
    assert Need1s.ok
    assert Need2s.ok
  end
  
  def test_values_override
    @admin.value1 = 10
    assert_equal 5, @admin.value1
    assert_equal 20, @admin.value2
    assert_equal 10, @admin._value1
  end
  
  def test_missing_value
    old = get_config( false, :DPuts, :silent )
    set_config( true, :DPuts, :silent )
    assert_raise( NoMethodError ){ @admin.value3 }
    assert_raise( RuntimeError ){ @admin._value3 }
    assert_nothing_raised{ @admin._value1 }
    set_config( old, :DPuts, :silent )
  end
  
  def test_create_key
    assert_equal( {}, Persons.keys )
    Persons.create_key_first_name

    assert_equal( {:first_name=>{"admin"=>1}}, Persons.keys )
  end
  
  def test_match_key
    Persons.create_key_first_name
    assert_equal( "super123", Persons.match_key_first_name( "admin" ).pass )
    assert_equal nil, Persons.match_key_first_name( "foo" )
    
    foo = Persons.create( :first_name => "foo", :pass => "bar" )
    assert_equal( "bar", Persons.match_key_first_name( "foo" ).pass )
    assert Persons.match_key_person_id( foo.id ), "Failed foo.id"
    assert Persons.match_key_person_id( foo.id.to_s ), "Failed string of foo.id"
  end
  
  def test_speed_match
    dputs(1){"Creating 1000 entries"}
    Persons.save_after_create = false
    (1..1000).each{ |i|
      Persons.create( :first_name => "name_#{i}", :pass => i )
    }
    (1..1).each{|i|
      dputs(1){"Benchmarking match - Turn #{i}"}
      dputs(1){ Benchmark.measure( "match_#{i}" ){
          (1..2000).each{|i|
            Persons.match_by( :first_name, "name_#{i}")
          }
        }.to_s
      }
    }
    (1..3).each{|i|
      dputs(1){"Benchmarking match_key - Turn #{i}"}    
      dputs(1){ Benchmark.measure( "match_key_#{i}" ){
          (1..2000).each{|i|
            Persons.match_key( :first_name, "name_#{i}")
          }
        }.to_s
      }
    }
  end
  
  def test_list_entity
    @base_1011.teacher = @admin
    assert_equal @admin, @base_1011.teacher
    Entities.save_all
    Entities.load_all
    assert_equal @admin, @base_1011.teacher
    
    course = Courses.create( :first_name => "foo",
      :students => [@admin] )
    course.students = [@admin]
    assert_equal @admin, course.students.first
    
    Entities.save_all
    Entities.load_all
    
    course = Courses.find_by_first_name( "foo" )
    assert_equal @admin, course.students.first
  end
end
