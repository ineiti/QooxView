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
  
  def test_set_config
    set_config( 1, :SetConfig )
    assert_equal 1, get_config( 2, :SetConfig )
    set_config( 2, :SetConfig )
    assert_equal 2, get_config( 3, :SetConfig )
    set_config( 2, :SetConfig2, :Level )
    assert_equal 2, get_config( 3, :SetConfig2, :Level )
    set_config( 3, :SetConfig2, :Level )
    assert_equal 3, get_config( 4, :SetConfig2, :Level )
    set_config( 4, :SetConfig3, :Level, :Two )
    assert_equal 4, get_config( 5, :SetConfig3, :Level, :Two )
  end
  
  def test_dputs_time
    dputs(1){"Testing time"}
    set_config( 'sec', :DPuts, :showTime )
    dputs(1){"First"}
    dputs(1){"Second"}
    sleep(1)
    dputs(1){"Third"}
  end
	
  def show_me
    @inside += 1
    return "hello"
  end
	
  def test_dputs
    old = get_config( false, :DPuts, :silent )
    set_config( true, :DPuts, :silent )

    @inside = 1
    dbg = DEBUG_LVL
    Object.send( :remove_const, :DEBUG_LVL )
    Object.const_set( :DEBUG_LVL, 1 )

    dputs( 1 ){ "Calling for show_me #{show_me}" }
    assert_equal 2, @inside
		
    dputs( 2 ){ "This shouldn't be called #{show_me}" }
    assert_equal 2, @inside

    Object.send( :remove_const, :DEBUG_LVL )
    Object.const_set( :DEBUG_LVL, dbg )

    set_config( old, :DPuts, :silent )
  end
	
  def test_speed_create
    dputs(1){"Benchmarking"}
    (0..4).each{|b|
      dputs(1){ Benchmark.measure( "Users #{(b*50).to_s.rjust(3)}" ){
          (1..50).each{|i|
            Entities.Persons.create( :first_name => "admin#{b*50+i}", :pass => "super123", :session_id => '0.1', :permission => 'admin' )
          }
        }.to_s
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
  
  def test_create_sqlite
    Accounts.create( :name => "test" )
  end

  def test_speed_sqlite
    dputs(1){"Benchmark"}
    (0..4).each{|b|
      dputs(1){ Benchmark.measure( "Accounts #{(b*50).to_s.rjust(3)}" ){
          (1..500).each{|i|
            Accounts.create( :name => "test" )
          }
        }.to_s
      }
    }
  end
end
