#!/usr/bin/ruby -I../..

require 'QooxView'

class Welcome < View
  def layout
    show_info :welcome, "hello world"
    show_button :welt, :world
  end

  # The button with the name "welt" is called
  def rpc_button_welt( sid, *args )
    reply( 'update', { :welcome => "Hallo Welt" } )
  end

  # The button with the name "world" is called
  def rpc_button_world( sid, *args )
    reply( 'update', { :welcome => "Hello world" } )
  end
end

QooxView::startWeb

