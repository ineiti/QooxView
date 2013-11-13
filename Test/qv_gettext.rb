require 'test/unit'
require 'gettext'

class TC_Gettext < Test::Unit::TestCase
  def setup
    dputs(0){"setting up"}
    $name = "gettext"
    GetText.bindtextdomain( 'gettext', :path => '/tmp' )
        GetText.bindtextdomain( $name, :path => "po" )
    GetText.locale = "en"
    GetText::TextDomainManager.cached = false
    dputs(0){"getting texts"}
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
