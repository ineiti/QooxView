require 'test/unit'

class TC_Helpers < Test::Unit::TestCase
  def setup
#    Entities.delete_all_data()
#    Entities.Persons.create( :first_name => "admin", :pass => "super123", :session_id => '0.1', :permission => 'admin' )
#    Entities.Persons.create( :first_name => "surf", :pass => "surf", :session_id => '0.2', :permission => 'internet' )
#    Permission.session_add( '0.1', 'admin')
#    Permission.session_add( '0.2', 'internet')
  end

  def teardown
  end

  def request( service, method, args )
    RPCQooxdooHandler.request(1, service, method, args )
  end

  def test_def_config
		assert_equal 777, get_config( 777, :TestConfigs )
		assert_equal true, get_config( nil, :TestConfig, :One )
		assert_equal "hello", get_config( nil, :TestConfig, :Two )
		assert_equal 30, get_config( nil, :TestConfig, :Three, :Thirty )
  end
end