require 'test/unit'
require 'gettext'

class TC_Gettext < Test::Unit::TestCase
  def setup
    GetText.bindtextdomain( 'gettext', 'po' )
    GetText.locale = "en"
    @a = GetText._("one")
    @b = GetText._("two")
  end

  def teardown
  end

  def test_domain
    GetText.locale = "fr"
    assert_equal "un", GetText._("one")
    assert_equal "one", @a
    assert_equal "deux", GetText._("two")
    assert_equal "two", @b
    assert_equal "hello", GetText._("hello")
  end
end
