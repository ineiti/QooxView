=begin
ViewType ListPane - a simple interface to use lists - rails-copy

Usage:

  include VTListPane

  gui_vbox do
    vtlp_list :names, 'nm'
    show_button :delete
  end
  gui_vbox do
    show_find :name
    show_str :login
    show_int :uid
  end

This will show a list with all available names. The data_class needs to have the following
methods defined (they're already defined if ":nm" exists in data_class):

  def list_nm
  end
  def find_nm
  end

The following buttons are defined:
 - new - clear the fields
 - save - saves the entry, eventually adding a new field
 - delete - takes away the chosen entry
=end

module VTListPane
  def vtlp_list( field, method )
    @vtlp_field = field.to_s
    @vtlp_method_list = "list_#{method}"
    @vtlp_method_find = "find_#{method}"
    show_list_single field, "Entities.#{@data_class.class.to_s}.list_#{method}", :callback => true
  end
  
  def vtlp_get_entity( data )
    field_data = @data_class.send( @vtlp_method_find, data[@vtlp_field][0] )
    if field_data
      @data_class.find_by( @data_class.data_field_id, field_data[@data_class.data_field_id] )
    else
      nil
    end
  end
  
  def vtlp_update_list( empty = true )
    rep = []
    if empty
      rep += reply( "empty", [ @vtlp_field.to_sym ] )
    end
    rep += reply( "update", { @vtlp_field.to_sym => @data_class.send( @vtlp_method_list ) } )
  end
  
  def rpc_button_new( sid, data )
    reply( "empty" )
  end
  
  def rpc_button_delete( sid, data )
    dputs 3, "sid, data: #{[sid, data.inspect].join(':')}"
    id = vtlp_get_entity( data )
    dputs 3, "Got #{id.inspect}"
    if id
      dputs 2, "Deleting entry #{id}"
      id.delete
    end
    
    vtlp_update_list
  end
  
  def rpc_button_save( sid, data )
    field = vtlp_get_entity( data )
    if field
      field.set_data( data.to_sym )
    else
      @data_class.create( data.to_sym )
    end
    vtlp_update_list
  end
  
  def rpc_list_choice( sid, name, *args )
    #Calling rpc_list_choice with [["courses", {"courses"=>["base_25"], "name_base"=>["base"]}]]
    dputs 3, "rpc_list_choice with #{name} - #{args.inspect}"
    if name == @vtlp_field
      field_value = args[0][name][0]
      dputs 3, "replying"
      ret = reply( "empty" )
      item = @data_class.send( @vtlp_method_find, field_value )
      if item
        ret += reply("update", item.to_hash )
      end
      ret += reply("update", {@vtlp_field.to_sym => [field_value] } )
    end
  end
end