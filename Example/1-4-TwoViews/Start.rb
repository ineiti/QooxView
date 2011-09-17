#!/usr/bin/ruby -I../..

# Show everything
DEBUG_LVL=5
require 'QooxView'

# Don't ask for a login (default action of Welcome-View)
Welcome.nologin

# Import our two views
require 'Overview'
require 'Detail'

# Start the webserver and RPC
QooxView::startWeb

