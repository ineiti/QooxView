class Welcome < View
  def layout
    
    gui_vbox :nogroup do
      gui_hbox :nogroup do
        gui_fields :nogroup do
        end
        show_str :username
        show_pass :password
        show_str_ro :version
        show_button :login
        gui_fields :nogroup do
        end
      end
      
      gui_window :login_failed do
        show_html :reason
        show_button :try_again
      end
      if get_config( false, :welcome_text )
        gui_vbox :nogroup do
          show_html :links
        end
      end
    end
        
    dputs( 5 ){ "#{@layout.inspect}" }
    @visible = false
  end
  
  def rpc_show( session )
    dputs( 3 ){ self.inspect }
    if @no_login
      dputs( 2 ){ "No login is enabled" }
      return reply( "session_id", "1" ) + 
        reply( "list", View.list_views )
    else
      dputs( 2 ){ "Login is enabled" }
      super( session )
    end
  end
  
  def self.nologin
    dputs( 2 ){ "Going for no login" }
    $config.merge!( {:views=>{:Welcome=>{:no_login=>true}}} )
  end
  
  def rpc_button_try_again( session, data )
    reply( "window_hide" )
  end
end
