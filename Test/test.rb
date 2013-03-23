#!/usr/bin/ruby -I..
require 'test/unit'
DEBUG_LVL = 2
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

tests = %w( entity permission stype sqlite gettext helpers migration
  view session )
#tests = %w( permission )
#tests = %w( view )
#tests = %w( permission )
tests.each{|t|
  require "qv_#{t}"
}
