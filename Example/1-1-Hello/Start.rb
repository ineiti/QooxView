#!/usr/bin/env ruby

require_relative '../dependencies'
require 'QooxView'

class Welcome < View
  def layout
    show_html :hi, '<h1>Hello world</h1>'
  end
end

QooxView::startWeb
