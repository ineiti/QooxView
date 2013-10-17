#!/usr/bin/ruby -I../..

require 'QooxView'

DEBUG_LVL=2

class Welcome < View
  def layout
    show_table :table, :headings => [:one, :two]
    show_button :populate, :pop_ind, :chosen
    
    gui_window :result do
      show_info :chosen_ones
      show_button :close
    end
  end

  def rpc_button_populate( session, args )
    reply( :update, :table => [[1,2,3],[4,5,6]])
  end
  
  def rpc_button_pop_ind( session, args )
    reply( :update, :table => [[1,[7,8,9]],[5,[10,11,12]]])
  end
  
  def rpc_button_chosen( session, args )
    dputs(0){"args is #{args.inspect}"}
  end
end

QooxView::startWeb

