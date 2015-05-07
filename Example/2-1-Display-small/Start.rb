#!/usr/bin/env ruby

require_relative '../dependencies'
require 'QooxView'

DEBUG_LVL=2

Welcome.nologin


class ResizeTabs < View
  def layout
    @order = 0
    gui_vbox :nogroup do
        show_str :search
    end
    @update = true
  end
end

class ResizesTabs < View
  def layout
  end
end

class ResizeIt < View
  def layout
    gui_vbox :nogroup do
      show_button :mylist, :yourlist
    end
  end
end

QooxView::startWeb

