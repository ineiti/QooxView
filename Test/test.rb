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
Permission.add( 'secretary', 'PersonModify', 'professor' )

qooxView = QooxView.init( 'entities', 'views' )

if false
else
  require 'qv_entity'
  require 'qv_permission'
  require 'qv_stype'
  require 'qv_sqlite'
  require 'qv_gettext'
  require 'qv_helpers'
  require 'qv_migration'
  require 'qv_view'
  require 'qv_session'
end
