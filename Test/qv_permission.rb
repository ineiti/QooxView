require 'test/unit'

class Tc_permission < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  def test_can_view
    assert Permission.can_view( 'internet', "Internet" ), "Internet is not allowed"
    assert ( not Permission.can_view( 'internet', "PersonModify" ) )
    assert Permission.can_view( 'secretary', "Internet" )
  end
  
  def test_inherit
    
  end
end