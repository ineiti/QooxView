#!/usr/local/bin/ruby -I.. -I.
require 'test/unit'
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
#tests = %w( gettext )
#tests = %w( configbase )
#tests = %w( permission )
tests.each{|t|
  require "qv_#{t}"
}
