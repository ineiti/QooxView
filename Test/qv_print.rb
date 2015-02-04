require 'test/unit'

class TC_Print < Test::Unit::TestCase
  def setup
    dputs(2){ 'Deleting everything'
    }
    Entities.delete_all_data
  end

  def teardown
  end
  
  def test_print_nup
    card = OpenPrint.new('Files/student_card.odg')
    if true
      card_1_pdf = card.print( [[/--NAME1--/, 'card1']], nil, 'name-1')
      card_2_pdf = card.print( [[/--NAME1--/, 'card2']], nil, 'name-2')
    else
      card_1_pdf = '/tmp/name-1.pdf'
      card_2_pdf = '/tmp/name-1.pdf'
    end
    assert_equal %w(/tmp/name-nup-front.pdf /tmp/name-nup-back.pdf),
      OpenPrint.pdf_nup_duplex( [card_1_pdf, card_2_pdf], 'name-nup')

    assert_equal %w(/tmp/name-nup-front.pdf /tmp/name-nup-back.pdf),
      OpenPrint.pdf_nup_duplex( [card_1_pdf], 'name-nup')
  end

  def test_print_formulas
    op = OpenPrint.new('Files/print_formulas_2.ods')
    op.print([%w(101 1), %w(102 2), %w(1002 1), %w(1003 2),
             %w(2010-08-20 2015-01-07)])
  end

  def test_openprint
    @admin = Entities.Persons.create( :login_name => 'admin', :password => 'super123',
                                      :permissions => ['default'] )
    @josue = Entities.Persons.create( :login_name => 'josue', :password => 'super',
                                      :permissions => ['default'] )

    mm = RPCQooxdooService.services['View.PrintView']
    sa = Sessions.create( @admin )
    sj = Sessions.create( @josue )
    PrintView.class_eval('
      def call_lpstat(ip)
        return []
      end ')

    assert_equal [:print_student], mm.printer_buttons

    assert_equal mm.reply(:update, :print_student => 'print_student PDF'),
                 mm.reply_print( sa )

    assert_equal mm.reply(:update, :print_student => 'print_student HP_LaserJet'),
                 mm.rpc_print( sa, :print_student, 'menu' => 'HP_LaserJet')

    assert_equal mm.reply(:update, :print_student => 'print_student HP_LaserJet'),
                 mm.rpc_print( sa, :print_student, {} )

    assert_equal mm.reply(:update, :print_student => 'print_student HP_LaserJet'),
                 mm.rpc_print( sa, :print_student, 'menu' => '')

    assert_equal 'HP_LaserJet', mm.stat_printer( sa, :print_student ).data_str
    assert_equal 'PDF', mm.stat_printer( sj, :print_student ).data_str

    assert_equal mm.reply(:update, :print_student => 'print_student HP_LaserJet2'),
                 mm.rpc_print( sj, :print_student, 'menu' => 'HP_LaserJet2')
    assert_equal 'HP_LaserJet', mm.stat_printer( sa, :print_student ).data_str
    assert_equal 'HP_LaserJet2', mm.stat_printer( sj, :print_student ).data_str
  end
end