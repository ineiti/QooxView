#!/usr/bin/env ruby

# Show everything
DEBUG_LVL=5

require_relative '../dependencies'
require 'QooxView'

# Don't ask for a login (default action of Welcome-View)
Welcome.nologin

# Import our two views
require_relative 'Overview'
require_relative 'Detail'

# Start the webserver and RPC
QooxView::startWeb

