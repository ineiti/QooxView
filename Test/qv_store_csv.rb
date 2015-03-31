require 'benchmark'

class TC_Store_CSV < Test::Unit::TestCase
  def setup
    dputs(2) { 'Deleting everything' }
    Entities.delete_all_data

    dputs(2) { 'Setting up data' }
    @admin = Persons.create(:first_name => 'admin', :pass => 'super123',
                                     :address => 'cdlf 24', :credit => 10000)
    Courses.create(:first_name => 'base_1010', :start => '1.10.2010')
    @base_1011 = Courses.create(:first_name => 'base_1011', :start => '1.11.2010',
                                         :teacher => @admin)
    @dummies_one = Dummies.create(:first_name => 'one', :phone => '111',
                                           :no_cache => '123')
    dputs(2) { 'Finished setting up data' }
  end

  def teardown
  end

  def test_dirty_flag
    Entities.save_all
    assert !@admin.changed
    assert !Persons.changed

    @admin.first_name = 'addmin'
    assert @admin.changed
    assert Persons.changed

    Entities.save_all
    assert !Persons.changed

    surf = Persons.create(:first_name => 'surfer')
    assert Persons.changed
    assert surf.changed
  end

  def get_persons_csv
    (Dir.glob('data/Persons.csv') +
        Dir.glob('data/backup/Persons.csv.*')).sort
  end

  def test_backup_count
    (0..5).each { |i|
      assert( get_persons_csv.size == i,
              "We don't have #{i} files, but #{get_persons_csv.size}: #{get_persons_csv.inspect}")
      @admin.first_name = "admin#{i}"
      Entities.save_all
    }
    assert get_persons_csv.size == 6
  end

  def test_dirty_data
    (0..5).each { |i|
      assert( get_persons_csv.size == i,
              "We don't have #{i} files, but #{get_persons_csv.size}: #{get_persons_csv.inspect}")
      @admin.first_name = "admin#{i}"
      Entities.save_all
    }

    Entities.load_all
    assert_equal 'admin5', Persons.find_by_pass('super123').first_name
    assert_equal 6, get_persons_csv.count

    # Test an invalid file - will the second-last be taken?
    File.open('data/Persons.csv', 'a') { |f|
      f.write('--no--valid--json--')
    }
    Entities.delete_all_data(true)
    Entities.load_all
    assert_equal 'admin4', Persons.find_by_pass('super123').first_name
    assert_equal 5, get_persons_csv.count

    # Invalidate everything
    get_persons_csv.each { |name|
      File.open(name, 'a') { |f|
        f.write('--no--valid--json--')
      }
    }

    Entities.delete_all_data(true)
    Entities.load_all
    assert_equal 1, get_persons_csv.count, get_persons_csv
  end
end
