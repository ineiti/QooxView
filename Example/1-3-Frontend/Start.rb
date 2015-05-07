#!/usr/bin/env ruby


DEBUG_LVL=5
CONFIG_FILE="config.yaml"
require_relative '../dependencies'
require 'QooxView'

class Welcome < View
  def layout
    @update = true
    @auto_update = 30
    @auto_update_send_values = false
    
    gui_vbox do
      show_html :title, "<div align='center'><h1>Gateway at MAF-compound</h1></div>"
      gui_vbox do
        gui_fields :noflex do
          show_info :Actual_Provider, `bin/get_connection`
        end
        show_button :ADSL, :Prestabist
      end
      
      show_html :ntop, ntop_table
      
      show_html :links, "
      <ul>
      <li>Backups: <a href='/backuppc'>Backuppc</a></li>
      <li>Network surveillance: <a href='/nagios3'>Nagios 3</a></li>
      <li>Documentation of the network: <a href='/dokuwiki'>Dokuwiki</a></li>
      </ul>
      "
    end
    rpc_button nil, 'ADSL', nil
  end
  
  def ntop_table
      "<table border=0 width='100%'><tr>
      <td width='50%'><img src='http://gateway:3000/plugins/rrdPlugin?action=arbreq&which=graph&arbfile=throughput&arbiface=eth1&arbip=&start=now-600&end=now&counter=&title=ADSL+10+Minutes+#{`date +%H:%M:%S`}' width=400 height=150></td>
      <td width='50%' align='right'><img src='http://gateway:3000/plugins/rrdPlugin?action=arbreq&which=graph&arbfile=throughput&arbiface=eth2&arbip=&start=now-600&end=now&counter=&title=PRESTABIST+10+Minutes+#{`date +%H:%M:%S`}' width=400 height=150></td>
      </tr><tr>
      </tr></table>"
  end
  
  def update( session )
    #   {:Actual_Provider => `bin/get_connection`, :ntop => ntop_table }
  end
  
  def rpc_button( session, name, *args )
    dputs( 0 ){ "switching to #{name}" }
    system "bin/set_connection #{name}"
    update( session )
  end
  
end

QooxView::startWeb
