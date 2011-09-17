require 'test/unit'

class Tc_permission < Test::Unit::TestCase
  def setup
    Permission.session_add( '0.1', 'internet')
    Permission.session_add( '0.2', 'secretary')
  end

  def teardown
  end

  def test_can
    assert Permission.can( '0.1', "Internet" ), "Internet is not allowed"
    assert ( not Permission.can( '0.1', "PersonModify" ) )
    assert Permission.can( '0.2', "Internet" )
  end
end