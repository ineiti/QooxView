#!/usr/bin/env ruby
#!/usr/local/bin/ruby -I.. -I.

$LOAD_PATH.push ".", ".."

require 'test/unit'
#require 'test/unit/testsuite'
DEBUG_LVL = 0
CONFIG_FILE='config.yaml'
require 'QooxView'
require 'st_dummy'

Permission.add( 'default', 'View,View.Login' )
Permission.add( 'admin', '.*', '.*' )
Permission.add( 'internet', 'Internet,PersonShow', 'default' )
Permission.add( 'student', '', 'internet' )
Permission.add( 'professor', '', 'student' )
Permission.add( 'cybermanager', '', '')
Permission.add( 'secretary', 'PersonModify,FlagAddInternet', 'professor,cybermanager' )

QooxView.init( 'entities', 'views' )

tests = %w( entity permission stype sqlite helpers migration
  view session configbase store_csv)
#tests = %w( permission )
#tests = %w( store_csv )
#tests = %w( configbase )

tests.each{|t|
  require "qv_#{t}"
}

$profiling = get_config( nil, :profiling )
if $profiling
  require 'rubygems'
  require 'perftools'
  PerfTools::CpuProfiler.start("/tmp/#{$profiling}") do
    Test::Unit::UI::Console::TestRunner.run(TC_Helpers)
  end
  puts "Now run the following:
    pprof.rb --pdf /tmp/#{$profiling} > /tmp/#{$profiling}.pdf
    open /tmp/#{$profiling}.pdf
    CPUPROFILE_FREQUENCY=500
  "
end


