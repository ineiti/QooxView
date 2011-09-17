#!/usr/bin/ruby -I../..

require 'QooxView'

class Welcome < View
  def layout
    show_info :welcome, "hello"
    show_info :there, "world"
  end
end

QooxView::startWeb
