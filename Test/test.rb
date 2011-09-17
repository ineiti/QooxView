#!/usr/bin/ruby -I..
require 'test/unit'
DEBUG_LVL = 5
CONFIG_FILE='config.yaml'
require 'QooxView'
require 'st_dummy'

Permission.add( 'default', 'View,View.Login' )
Permission.add( 'admin', '.*' )
Permission.add( 'internet', 'Internet,PersonShow', 'default' )
Permission.add( 'student', '', 'internet' )
Permission.add( 'professor', '', 'student' )
Permission.add( 'secretary', 'PersonModify', 'professor' )

qooxView = QooxView.init( 'entities', 'views' )

#require 'qv_africompta'
require 'qv_entity'
#require 'qv_permission'
#require 'qv_view'
#require 'qv_stype'
#require 'qv_new'
