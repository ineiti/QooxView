require 'test/unit'
require 'qooxview/config_yaml'

class TC_Config < Test::Unit::TestCase
  def setup
    Entities.delete_all_data
  end
  
  def teardown
  end

  def test_search
    dir = '/tmp/tconf/search/up/'
    dir2 = '/tmp/tconf/'
    conf = 'config.yaml'
    FileUtils.rm_rf(dir2)
    FileUtils.mkdir_p(dir)
    dir = File.realdirpath(dir)
    dir2 = File.realdirpath(dir2)

    assert_nil search_up(conf, dir)

    conf1 = File.join(dir2, conf)
    FileUtils.touch(conf1)
    assert_equal conf1, search_up(conf, dir)

    conf2 = File.join(dir, conf)
    FileUtils.touch(conf2)
    assert_equal conf2, search_up(conf, dir)

    FileUtils.rm_rf(dir2)
  end

  def test_load
    IO.write('/tmp/qooxview.conf', '
# This is a config-file
CONF1=hi

  # Empty lines

# Spaces in "=" - not allowed
 CONF2 = there

# Comment after value
CONF3=hi_there# comment

# Space in value - not taken into account
CONF4=hi there

# Quotes
CONF5="hi there" # comment

# Quotes with comment
CONF6="hi #there" # comment
')
    $name = 'qooxview'
    load_config_global('/tmp')
    assert_equal 'hi', $config[:CONF1]
    assert_equal nil, $config[:CONF2]
    assert_equal 'hi_there', $config[:CONF3]
    assert_equal 'hi', $config[:CONF4]
    assert_equal 'hi there', $config[:CONF5]
    assert_equal 'hi #there', $config[:CONF6]
  end
end