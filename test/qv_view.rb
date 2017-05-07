require 'test/unit'

class SimulWebReq
  def self.header
    {}
  end

  def self.peeraddr
    [0, 0, 0, 0]
  end
end

class TC_View < Test::Unit::TestCase
  def setup
    Entities.delete_all_data()
    @admin = Entities.Persons.create(:first_name => 'admin', :pass => 'super123',
                                     :permissions => 'admin')
    @surf = Entities.Persons.create(:first_name => 'surf', :pass => 'surf',
                                    :permissions => 'internet', :credit => 5000)
    @autre = Entities.Persons.create(:first_name => 'autre', :pass => 'surf',
                                     :permissions => 'internet', :credit => 5000)
    @base = Entities.Courses.create(:first_name => 'base_10', :teacher => @surf)
    @session_admin = Sessions.create(@admin, '0.1')
    @session_surf = Sessions.create(@surf, '0.2')
  end

  def teardown
  end

  def request(service, method, args)
    RPCQooxdooHandler.request(1, service, method, args, SimulWebReq)
  end

  def make_list(configs = [])
    ([%w(BView BView),
      %w(CView CView),
      %w(CourseShow CourseShow),
      %w(AView AView),
      %w(PrintView PrintView)] +
        configs.collect { |c|
          %W(ConfigView#{c} ConfigView#{c}) }).sort
  end

  def test_order
    View.update_configured_all
    reply = request('View', 'list', [['0.1']])
    dputs(1) { reply['result'].inspect }
    assert_equal [%w(BView BView),
                  %w(CView CView),
                  %w(ConfigView2 ConfigView2),
                  %w(CourseShow CourseShow),
                  %w(PrintView PrintView),
                  %w(AView AView)],
                 reply['result'][0][:data][:views]
  end

  def test_update
    reply = request('View.AView', 'update', [['0.1']])
    result = reply['result'][0][:data][0][:data]
    dputs(4) { "Reply is #{reply.inspect} - result is #{result.inspect}" }
    assert_equal 'admin', result[:first_name], result.inspect
    assert !result.key(:permission)
  end

  def test_show
    reply = request('View.CView', 'show', [['0.1']])
    result = reply['result']
    assert_equal [{:cmd => 'show',
                   :data =>
                       {:view_class => 'CView',
                        layout: ['group',
                                 [['vbox',
                                   [['group',
                                     [['hbox',
                                       [['group',
                                         [['fields', [['int', :person_id, 'person_id', {:id => true}]]],
                                          ['vbox', [[:button, :new, 'new', {}]]]]]]]]],
                                    ['group',
                                     [['hbox',
                                       [['group',
                                         [['fields',
                                           [['str', :first_name, 'first_name', {:callback => 'yes', :width => 300}],
                                            ['str', :pass, 'pass', {:width => 300}]]]]]]]]],
                                    ['window:cview',
                                     [['group',
                                       [['fields',
                                         [['int', :counter, 'counter', {:min => 10, :max => 20}],
                                          ['str', :street, 'street', {:hidden => true}]]]]]]]]]]],
                        :data_class => 'Persons'}}],
                 result
  end

  def test_config
    assert_equal 2, View.Welcome.order
  end

  def test_layout
    assert_equal ['group',
                  [['fields',
                    [['int', :person_id, 'person_id', {:id => true}],
                     ['str', :first_name, 'first_name', {}],
                     ['str', :pass, 'pass', {}],
                     ['str', :address, 'address', {}],
                     ['int', :credit, 'credit', {}],
                     ['int', :ro_int, 'ro_int', {:ro => true}],
                     ['list', :ro_list, 'ro_list', {:ro => true, :list_values => [1, 2, 3]}],
                     ['list', :ro_list2, 'ro_list2', {:ro => true}],
                     ['fromto', :duration, 'duration', {}],
                     ['list', :worker, 'worker', {:list_values => %w(admin autre surf)}]]]]],
                 View.AView.layout_eval
  end

  def test_list_update
    assert_equal ['list', :worker, 'worker', {:list_values => %w(admin autre surf)}],
                 View.AView.layout_eval[1][0][1][9],
                 View.AView.layout_eval.inspect
    Entities.Persons.create(:first_name => 'foo', :pass => 'foo',
                            :session_id => '0.3', :permission => 'internet')
    assert_equal ['list', :worker, 'worker', {:list_values => %w(admin autre foo surf)}],
                 View.AView.layout_eval[1][0][1][9]
  end

  def test_filter_from_entity
    data = Hash[*%w( l_a 1 l_b 2 l_c 3 l_d 4 )]
    assert_equal Hash[*%w( l_b 2 )], View.AView.filter_from_entity(data)
    assert_equal Hash.new, View.AView.filter_from_entity(Hash.new)
    assert_equal Hash.new, View.AView.filter_from_entity(nil)
    data.delete('l_b')
    assert_equal Hash.new, View.AView.filter_from_entity(Hash.new)
  end

  def test_view_subclass
    assert_equal 2, View.AView.test_sub
  end

  def tes_view_entities
    assert_equal ['group',
                  [['fields',
                    [['list',
                      :teacher,
                      'teacher',
                      {:list_type => :drop,
                       :all => true,
                       :list_values => [[3, 'autre'], [2, 'surf']]}],
                     ['list',
                      :assistant,
                      'assistant',
                      {:list_type => :drop,
                       :all => true,
                       :list_values => [[0, '---'], [1, 'admin'], [3, 'autre'], [2, 'surf']],
                       :empty => true}],
                     ['list',
                      :students,
                      'students',
                      {:list_type => :single, :list_values => []}]]]]],
                 View.CourseShow.layout_eval
    @admin.credit = 2000
    assert_equal ['group',
                  [['fields',
                    [['list',
                      :teacher,
                      'teacher',
                      {:list_type => :drop,
                       :all => true,
                       :list_values => [[1, 'admin'], [3, 'autre'], [2, 'surf']]}],
                     ['list',
                      :assistant,
                      'assistant',
                      {:list_type => :drop,
                       :all => true,
                       :list_values => [[0, '---'], [1, 'admin'], [3, 'autre'], [2, 'surf']],
                       :empty => true}],
                     ['list',
                      :students,
                      'students',
                      {:list_type => :single, :list_values => []}]]]]],
                 View.CourseShow.layout_eval
  end

  def test_parse_request
    params = View.CourseShow.parse_request(0, 0, ['test', {'one' => 2,
                                                           'teacher' => @surf.id}])
    assert_equal @surf.id, params[1]['teacher']
  end

  def test_configured
    ConfigBase.store(function: [])
    assert_equal make_list([2]), View.list(@session_admin)[:views].sort

    ConfigBase.store(functions: [1])
    assert_equal make_list([1, 2]),
                 View.list(@session_admin)[:views].sort

    ConfigBase.value = :one
    ConfigBase.store
    assert_equal make_list([1, 2, 3]),
                 View.list(@session_admin)[:views].sort

    ConfigBase.store(functions: [1, 2])
    assert_equal make_list([1]),
                 View.list(@session_admin)[:views].sort
  end
end
