require 'benchmark'

class TC_Store_CSV < Test::Unit::TestCase
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

  def test_dirty_flag
    Entities.save_all
    assert ! @admin.changed
    assert ! Persons.changed

    @admin.first_name = 'addmin'
    assert @admin.changed
    assert Persons.changed

    Entities.save_all
    assert ! Persons.changed

    surf = Persons.create( :first_name => 'surfer')
    assert Persons.changed
    assert surf.changed
  end

  def get_persons_csv
    Dir.glob('data/Persons.csv.*').sort
  end

  def test_backup_count
    (0..5).each{|i|
      assert get_persons_csv.size == i, "We don't have #{i} files"
      Entities.save_all
      @admin.first_name = "admin#{i}"
    }
    assert get_persons_csv.size == 5
  end

  def test_dirty_data
    (0..5).each{|i|
      assert get_persons_csv.size == i, "We don't have #{i} files"
      @admin.first_name = "admin#{i}"
      Entities.save_all
    }
    File.open( get_persons_csv.last, 'a' ){|f|
      f.write( '--no--valid--json--' )
    }
    Entities.load_all
    assert_equal 'admin4', Persons.find_by_pass('super123').first_name
    assert_equal 4, get_persons_csv.count

    get_persons_csv.each{|name|
      File.open( name, 'a' ){|f|
        f.write( '--no--valid--json--' )
      }
    }
    assert_raise(StorageLoadError){Entities.load_all}
    assert_equal 0, get_persons_csv.count, get_persons_csv
  end
end
