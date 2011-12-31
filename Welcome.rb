class Welcome < View
  def layout
    
    gui_hbox :nogroup do
      show_str :username
      show_pass :password
      show_button :login
      
      gui_window :login_failed do
        show_str :reason
        show_button :try_again
      end
    end
    
    dputs 5, "#{@layout.inspect}"
    @visible = false
  end
  
  def rpc_show( session )
    dputs 3, self.inspect
    if @no_login
      dputs 2, "No login is enabled"
      return reply( "session_id", "1" ) + 
      reply( "list", View.list_views )
    else
      dputs 2, "Login is enabled"
      super( session )
    end
  end
  
  def self.nologin
    dputs 2, "Going for no login"
    $config.merge!( {:views=>{:Welcome=>{:no_login=>true}}} )
  end
  
  def rpc_button_try_again( session, data )
    reply( "window_hide" )
  end
end
