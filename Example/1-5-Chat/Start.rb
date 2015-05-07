#!/usr/bin/env ruby

# A very simple chat program - everybody can
# join in and chose a name
# The conversation shows the last 10 messages, without scrolling

require_relative '../dependencies'
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
  def rpc_button_talk( session, *args )
    @conv.push "#{args[0]['name']}: #{args[0]['msg']}"
    reply( :update, :msg => "" ) +
    rpc_update_with_values( session, "" )
  end

  def rpc_update_with_values( session, args )
    reply( :update, :conversation => @conv.last(10).reverse.join("\n") )
  end
end

QooxView::startWeb

