require 'test/unit'

class Tc_permission < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  def test_can_view
    assert Permission.can_view( 'internet', 'Internet'), 'Internet is not allowed'
    assert ( not Permission.can_view( 'internet', 'PersonModify') )
    assert Permission.can_view( 'secretary', 'Internet')
  end
  
  def test_views
    assert_equal %w( View View.Login ), Permission.views( :default )
    assert_equal %w( Internet PersonShow View View.Login ), 
      Permission.views( :internet )
    assert_equal %w( Internet PersonShow View View.Login ), 
      Permission.views( %w( internet default ) )
  end

  def test_has_role
    assert Permission.has_role( 'professor', 'professor' )
    assert ! Permission.has_role( 'professo', 'professor' )
    assert ! Permission.has_role( 'rofessor', 'professor' )
    assert Permission.has_role( 'admin', 'professor' )
    assert ! Permission.has_role( 'student', 'professor' )
    assert Permission.has_role( %w( professor secretary ), 'cybermanager' )
    assert Permission.has_role( %w( secretary professor ), 'cybermanager' )
  end
  
end