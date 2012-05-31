#!/usr/bin/ruby -I../..

require 'QooxView'

class Welcome < View
  def layout
    show_html :hi, "<h1>Hello world</h1>"
  end
end

QooxView::startWeb
