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
    session = Sessions.create( @admin )
    dputs( 0 ){ "#{session.inspect}" }
    assert_equal @admin.session_id, session.sid
    assert_equal "admin", session.owner.first_name
    
    search = Sessions.find_by_sid( session.sid )
    assert_equal session.sid, search.sid
    
    search.close
    assert_equal nil, Sessions.find_by_sid( session.sid )
  end
end