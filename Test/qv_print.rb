require 'test/unit'

class TC_Print < Test::Unit::TestCase
  def setup
    dputs(2){"Deleting everything"}
    Entities.delete_all_data
  end

  def teardown
  end
  
  def test_print_nup
    card = OpenPrint.new( "Files/student_card.odg" )
    card_1_pdf = card.print( [[/--NAME1--/, "card1"]], nil, "name-1")
    card_2_pdf = card.print( [[/--NAME1--/, "card2"]], nil, "name-2")
    assert_equal ["/tmp/name-nup-1.pdf", "/tmp/name-nup-2.pdf"], 
      OpenPrint.print_nup( [card_1_pdf, card_2_pdf], "name-nup" )
  end

end