require 'benchmark'
require 'securerandom'

class TC_ICC < Test::Unit::TestCase
  def setup
    dputs(2) { "Deleting everything" }
    Entities.delete_all_data

    @admin = Persons.create(login_name: 'admin', password_plain: '1234')
  end

  def teardown
  end

  def test_transfer
    @port = 3302
    url = "http://localhost:#{@port}/icc"
    main = Thread.new {
      QooxView::startWeb(@port)
    }
    dputs(1) { "Starting at port #{@port}" }
    sleep 1

    ICC.transfer(@admin, 'Persons.adduser', {:first_name => 'foo', :pass => 'bar'},
                 url: url)

    fb = Persons.find_by_first_name( 'foo' )
    assert_equal 'bar', fb.pass

    ICC.transfer(@admin, 'Persons.longtransfer', SecureRandom.random_bytes(16384),
                 url: url)
    assert_equal 16384, Persons.get_longtransfer_bytes

    @str = ''
    ICC.transfer(@admin, 'Persons.longtransfer', SecureRandom.random_bytes(1024),
                 url: url){|s| @str += s}
    assert_equal '50%100%', @str

    main.kill.join
  end

end
