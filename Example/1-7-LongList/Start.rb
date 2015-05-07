#!/usr/bin/env ruby

require_relative '../dependencies'
require 'QooxView'

DEBUG_LVL=2

Welcome.nologin

class PersonEdit < View
  def layout
    gui_vbox do
      show_list :hi, :flexheight => 1
    end
    @update = true
  end

  def rpc_update( session )
    reply( :update, :hi => (1..30).collect{|a| [a,a] } )
  end
end

QooxView::startWeb

