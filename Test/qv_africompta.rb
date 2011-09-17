require 'test/unit'

class TC_New < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  def test_africompta
    link = AfriCompta.new( 'Caisse::Main',
    'Emprunts::Josué',
    'gestion', 'gestion777')
    
    old_credit = link.getCredit
    new_credit = link.addMovement( 0, 10.0 )
    
    assert_equal new_credit - 10.0, old_credit
  end
end