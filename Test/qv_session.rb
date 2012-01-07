require 'test/unit'

class TC_Session < Test::Unit::TestCase
  def setup
    Entities.delete_all_data
    @admin = Entities.Persons.create( :first_name => "admin", :pass => "super123",
    :address => "cdlf 24", :credit => 10000 )
    Entities.Courses.create( :first_name => "base_1010", :start => "1.10.2010")
    Entities.Courses.create( :first_name => "base_1011", :start => "1.11.2010")
    @dummies_one = Entities.Dummies.create( :first_name => "one", :phone => "111",
    :no_cache => "123" )
  end

  def teardown
  end

  def test_new_session
    session = Session.new( @admin )
    dputs 0, @session.inspect
    assert_equal @admin.session_id, session.id
    assert_equal "admin", session.owner.first_name
    
    search = Session.find_by_id( session.id )
    assert_equal session.id, search.id
  end
end