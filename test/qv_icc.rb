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

  def with_server
    ConfigBase.block_size = 4096

    @port = 3302
    @url = "http://localhost:#{@port}/icc"
    @main = Thread.new {
      QooxView::startWeb(@port)
    }
    dputs(1) { "Starting at port #{@port}" }
    sleep 1

    yield @port, @url, @main

    @main.kill.join
  end

  def test_transfer
    with_server do
      ICC.transfer(@admin, 'Persons.adduser', {:first_name => 'foo', :pass => 'bar'},
                   url: @url)

      fb = Persons.find_by_first_name('foo')
      assert_equal 'bar', fb.pass

      ICC.transfer(@admin, 'Persons.longtransfer', SecureRandom.random_bytes(16384),
                   url: @url)
      assert_equal 16384, Persons.get_longtransfer_bytes

      @str = ''
      ICC.transfer(@admin, 'Persons.longtransfer', SecureRandom.random_bytes(1500),
                   url: @url) { |s| @str += s }
      assert_equal '0%50%100%', @str
    end
  end

  def test_fetch_binary
    with_server do
      ret = ICC.get(:Persons, :_getbinary, url: @url)
      file1 = ret._msg
      file2 = IO.read('file_binary.bin').force_encoding(Encoding::ASCII_8BIT)
      assert Digest::MD5.hexdigest(file1) == Digest::MD5.hexdigest(file2)
      assert file1 == file2
    end
  end

end
