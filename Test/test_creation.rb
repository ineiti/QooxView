#!/usr/bin/env ruby -I.. -I.
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

require 'rubygems'
require 'perftools'
PerfTools::CpuProfiler.start("/tmp/profile.create") do
  Entities.delete_all_data()
  Benchmark.bm{|x|
			
    (0..4).each{|b|
      x.report( "Users #{(b*50).to_s.rjust(3)}" ){
        (1..50).each{|i|
          Entities.Persons.create( :first_name => "admin#{b*50+i}", :pass => "super123", :session_id => '0.1', :permission => 'admin' )
        }
      }
    }
  }
end

puts 'Now run the following:
    pprof.rb --pdf /tmp/profile.create > /tmp/profile.create.pdf
    open /tmp/profile.create.pdf
    CPUPROFILE_FREQUENCY=500
'
