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
    if true
      card_1_pdf = card.print( [[/--NAME1--/, "card1"]], nil, "name-1")
      card_2_pdf = card.print( [[/--NAME1--/, "card2"]], nil, "name-2")
    else
      card_1_pdf = "/tmp/name-1.pdf"
      card_2_pdf = "/tmp/name-1.pdf"
    end
    assert_equal ["/tmp/name-nup-front.pdf", "/tmp/name-nup-back.pdf"], 
      OpenPrint.print_nup_duplex( [card_1_pdf, card_2_pdf], "name-nup" )

    assert_equal ["/tmp/name-nup-front.pdf", "/tmp/name-nup-back.pdf"], 
      OpenPrint.print_nup_duplex( [card_1_pdf], "name-nup" )
  end

end