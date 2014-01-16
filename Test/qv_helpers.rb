require 'test/unit'

class TC_Helpers < Test::Unit::TestCase
  def setup
    Entities.delete_all_data()
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
	
  def show_me
    @inside += 1
    return "hello"
  end
	
  def test_dputs
    @inside = 1
    dputs( 0 ){ "Calling for show_me #{show_me}" }
    assert_equal 2, @inside
		
    dputs( 6 ){ "This shouldn't be called #{show_me}" }
    assert_equal 2, @inside
  end
	
  def test_speed_create
    Benchmark.bm{|x|
			
      (0..4).each{|b|
        x.report( "Users #{(b*50).to_s.rjust(3)}" ){
          (1..50).each{|i|
            Entities.Persons.create( :first_name => "admin#{b*50+i}", :pass => "super123", :session_id => '0.1', :permission => 'admin' )
          }
        }
      }
    }
  end
  
  def test_config_list
    assert_equal ["one", "two three"], get_config( nil, :TestList )

    assert_equal ["Link: <a href='hello there'>link</a>"], 
      get_config( nil, :TestLink1 )

    assert_equal "Something over\nmultiple lines:\none two three\n", 
      get_config( nil, :TestLink2 )
  end
end
