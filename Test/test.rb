#!/usr/local/bin/ruby -I.. -I.
require 'test/unit'
#require 'test/unit/testsuite'
DEBUG_LVL = 0
CONFIG_FILE='config.yaml'
require 'QooxView'
require 'st_dummy'

Permission.add( 'default', 'View,View.Login' )
Permission.add( 'admin', '.*' )
Permission.add( 'internet', 'Internet,PersonShow', 'default' )
Permission.add( 'student', '', 'internet' )
Permission.add( 'professor', '', 'student' )
Permission.add( 'secretary', 'PersonModify,FlagAddInternet', 'professor' )

QooxView.init( 'entities', 'views' )

tests = %w( entity permission stype sqlite helpers migration
  view session configbase )
tests = %w( helpers )
#tests = %w( configbase )
#tests = %w( permission )

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


