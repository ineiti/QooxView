require 'test/unit'



class TC_View < Test::Unit::TestCase
  def setup
    Entities.delete_all_data()
    @admin = Entities.Persons.create( :first_name => "admin", :pass => "super123",
    :permissions => 'admin' )
    @surf = Entities.Persons.create( :first_name => "surf", :pass => "surf",
    :permissions => 'internet', :credit => 5000 )
    @autre = Entities.Persons.create( :pass => "surf",
    :permissions => 'internet', :credit => 5000 )
    @base = Entities.Courses.create( :first_name => "base_10", :teacher => @surf )
    Session.new( @admin, '0.1' )
    Session.new( @surf, '0.2' )
  end

  def teardown
  end

  def request( service, method, args )
    RPCQooxdooHandler.request(1, service, method, args )
  end

  def test_order
    reply = request( "View", 'list', [['0.1']] )
    dputs 0, reply['result'].inspect
    assert_equal ["BView", "CView", "CourseShow", "AView"], reply['result'][:views]
  end

  def test_update
    reply = request( 'View.AView', 'update', [['0.1']] )
    result = reply['result'][0][:data]
    assert_equal "admin", result[:first_name], result.inspect
    assert result[:permission] == nil
  end

  def test_show
    reply = request( 'View.CView', 'show', [['0.1']])
    result = reply['result']
    assert_equal [{:cmd=>"show",
  :data=>
   {:view_class=>"CView",
    :layout=>
     ["group",
      [["vbox",
        [["group",
          [["hbox",
            [["group",
              [["fields", [["int", :person_id, :person_id, {:id=>true}]]],
               ["vbox", [[:button, :new, :new, nil]]]]]]]]],
         ["group",
          [["hbox",
            [["group",
              [["fields",
                [["str", :first_name, :first_name, {:callback=>"yes"}], ["str", :pass, :pass, {}]]]]]]]]],
         ["window:cview",
          [["group",
            [["fields",
              [["int", :counter, :counter, {:min=>10, :max=>20}],
               ["str", :street, :street, {:hidden=>true}]]]]]]]]]]],
    :data_class=>"Persons"}}],
     result
  end

  def test_config
    assert_equal true, View.Welcome.need_pass
    assert_equal false, View.Welcome.hide_pass
  end

  def test_layout
    assert_equal ["group",
 [["fields",
   [["int", :person_id, :person_id, {:id=>true}],
    ["str", :first_name, :first_name, {}],
    ["str", :pass, :pass, {}],
    ["str", :address, :address, {}],
    ["int", :credit, :credit, {}],
    ["int", :session_id, :session_id, {}],
    ["int", :ro_int, :ro_int, {:ro=>true}],
    ["list", :ro_list, :ro_list, {:ro=>true, :list_values=>[1,2,3]}],
    ["list", :ro_list2, :ro_list2, {:ro=>true}],
    ["fromto", :duration, :duration, {}],
    ["list", :worker, :worker, {:list_values=>["admin","surf",nil]}]]]]],
     View.AView.layout_eval
  end

  def test_list_update
    assert_equal ["list", :worker, :worker, {:list_values=>["admin","surf",nil]}],
      View.AView.layout_eval[1][0][1][10],
      View.AView.layout_eval.inspect
    Entities.Persons.create( :first_name => "foo", :pass => "foo",
    :session_id => '0.3', :permission => 'internet' )
    assert_equal ["list", :worker, :worker, {:list_values=>["admin","surf",nil,"foo"]}],
      View.AView.layout_eval[1][0][1][10]
  end

  def test_filter_from_entity
    data = Hash[*%w( l_a 1 l_b 2 l_c 3 l_d 4 )]
    assert_equal Hash[*%w( l_b 2 )], View.AView.filter_from_entity( data )
    assert_equal Hash.new, View.AView.filter_from_entity( Hash.new )
    assert_equal Hash.new, View.AView.filter_from_entity( nil )
    data.delete( 'l_b' )
    assert_equal Hash.new, View.AView.filter_from_entity( Hash.new )
  end

  def test_view_subclass
    assert_equal 2, View.AView.test_sub
  end

  def test_view_entities
    assert_equal ["group", [["fields", [["list", :teacher, :teacher,
      {:list_values=>[["1","surf"]], :list_type=>:drop}]]]]],
      View.CourseShow.layout_eval
    @admin.credit = 2000
    assert_equal ["group", [["fields", [["list", :teacher, :teacher,
      {:list_values=>[["0","admin"],["1","surf"]], :list_type=>:drop}]]]]],
      View.CourseShow.layout_eval
  end
  
  def test_parse_reply
    params = View.CourseShow.rpc_parse_reply( 0, 0, ["test", { "one" => 2,
      "teacher" => @surf.id } ] )
    assert_equal "surf", params[1][:teacher].first_name 
  end
end
