#!/usr/bin/ruby -I../..
# A very simple chat program - everybody can
# join in and chose a name
# The conversation shows the last 10 messages, without scrolling

require 'QooxView'

class Welcome < View
  def layout
    @conv = []
    @auto_update = 5
    show_str :msg
    show_text :conversation
    show_str :name
    show_button :talk
  end

  # Sending a message
  def rpc_button_talk( sid, *args )
    @conv.push "#{args[0]['name']}: #{args[0]['msg']}"
    reply( 'update', { :msg => "" } ) +
    rpc_update_with_values( sid, "" )
  end

  def rpc_update_with_values( sid, args )
    reply( 'update', { :conversation => @conv.last(10).reverse.join("\n") } )
  end
end

QooxView::startWeb

