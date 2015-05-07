#!/usr/bin/env ruby

require_relative '../dependencies'
require 'QooxView'

DEBUG_LVL=2

class Welcome < View
  def layout
    gui_vbox do
      show_table :table, headings: [:one, :two], edit: [1]
      show_button :populate, :pop_ind, :chosen
      show_button :chose_one, :chose_two

      gui_window :result do
        show_info :chosen_ones
        show_button :close
      end
    end
  end

  def rpc_button_populate(session, args)
    reply(:update, :table => [[1, 2, 3], [4, 5, 6]])
  end

  def rpc_button_pop_ind(session, args)
    reply(:update, :table => [[1, [7, 8, 9]], [5, [10, 11, 12]]])
  end

  def rpc_button_chosen(session, args)
    dputs(0) { "args is #{args.inspect}" }
  end

  def rpc_button_chose_one(_session, _data)
    reply(:focus, {table: 'table', col: 1, row: 0})
  end

  def rpc_button_chose_two(_session, _data)
    reply(:focus, {table: 'table', col: 1, row: 1})
  end
end

QooxView::startWeb

