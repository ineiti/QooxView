%w( QooxView HelperClasses/lib ).each{|p|
  $LOAD_PATH.push File.expand_path("../../../#{p}", __FILE__)
}
