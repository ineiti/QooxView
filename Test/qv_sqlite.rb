require 'test/unit'

class TC_Entity < Test::Unit::TestCase
  def setup
#    Entities.delete_all_data
    Entities.Movements.create( :desc => "salaire", :money => 100 )
  end

  def teardown
  end

  def test_create
  end

end