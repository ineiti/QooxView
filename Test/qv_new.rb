require 'test/unit'

class TC_New < Test::Unit::TestCase
  def setup
    Entities.delete_all_data()
    Entities.Persons.create( :first_name => "admin", :pass => "super123", :session_id => '0.1', :permission => 'admin' )
    Entities.Persons.create( :first_name => "surf", :pass => "surf", :session_id => '0.2', :permission => 'internet' )
    Permission.session_add( '0.1', 'admin')
    Permission.session_add( '0.2', 'internet')
  end

  def teardown
  end

  def request( service, method, args )
    RPCQooxdooHandler.request(1, service, method, args )
  end

  def test_to_json
    reply = request( 'View.DView', 'show', [['0.1']])
    result = reply['result'].to_json
    assert_equal result, "", reply.inspect
  end
end