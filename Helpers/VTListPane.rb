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
  def vtlp_setup( field, method, *args )
    @vtlp_field = field.to_s
    @vtlp_method = method.to_s.sub( /^rev_/, "" )
    if args.length > 0 and args[0].class == String
      @vtlp_method_list = args.shift
    else
      @vtlp_method_list = "listp_#{method.to_s}"
    end
    if args.length > 0 and args[0].class == Hash
      args.shift
    else
      {}
    end
  end
  
  def vtlp_list( field, method, *args )
    @vtlp_use_entity = false
    args_hash = vtlp_setup( field, method, *args )
    show_list_single field, "Entities.#{@data_class.class.to_s}.#{@vtlp_method_list}", 
      args_hash.merge( :callback => true )
  end
  
  def vtlp_list_entity( field, entity, method, *args )
    @vtlp_use_entity = true
    args_hash = vtlp_setup( field, method, *args )
    show_entity field, entity, "single",
      @vtlp_method, 
      args_hash.merge( :callback => true )    
  end
  
  def vtlp_get_entity( d )
    @vtlp_use_entity ? d : @data_class.get_data_instance( d[@vtlp_field][0] )
  end
  
  def vtlp_update_list( session, choice = nil )
    list = @data_class.send( @vtlp_method_list )
    rep = reply( :empty, @vtlp_field ) + if choice
      reply( :update_callback, @vtlp_field => list + [choice] )
      #      list += [ choice ]
    else
      reply( :update, @vtlp_field.to_sym => list )
    end
    
    if @update
      rep += rpc_update( session )
    end
    rep
  end
  
  def rpc_button_new( session, data )
    vtlp_update_list( session )
  end
  
  def rpc_button_delete( session, data )
    dputs( 3 ){ "session, data: #{[session, data.inspect].join(':')}" }
    id = vtlp_get_entity( data )
    dputs( 3 ){ "Got #{id.inspect}" }
    if id
      dputs( 2 ){ "Deleting entry #{id}" }
      id.delete
    end
    
    vtlp_update_list( session )
  end
  
  def rpc_button_save( session, data )
    field = vtlp_get_entity( data )
    dputs( 2 ){ "Field is #{field.inspect}, setting data #{data.inspect}" }
    selection = data[@vtlp_field][0]
    if field
      field.data_set_hash( data.to_sym )
    else
      if data[ @vtlp_method ].to_s.length > 0
        n = @data_class.create( data.to_sym )
        selection = n.id
      else
        dputs( 0 ){ "Didn't have a #{@vtlp_method}"}
      end
    end
    dputs(3){"vtlp_method is #{@vtlp_method} - selection is #{selection.inspect}"}
    vtlp_update_list( session, selection )
    #      [data[@vtlp_field][0], field.data_get(@vtlp_method)] )
  end
  
  def rpc_list_choice( session, name, data )
    ret = if @update and @update == :before
      rpc_update( session )
    else
      []
    end
    dputs( 3 ){ "rpc_list_choice with #{name} - #{data.inspect}" }
    if name == @vtlp_field
      ret = reply( :empty )
      item = if @vtlp_use_entity
        field_value = data[name].get_unique
        data[name]
      else
        field_value = data[name][0]
        dputs( 4 ){ "replying with field_value of #{field_value}" }
        vtlp_get_entity(data)
      end
      dputs( 4 ){ "item is #{item.inspect}" }
      if item
        ret += reply( :update, item.to_hash )
      end
      ret += reply( :update, {@vtlp_field.to_sym => [field_value] } )
    end
    if @update and @update != :before
      ret += rpc_update( session )
    end

    dputs( 3 ){ "reply is #{ret.inspect}" }
    ret
  end
end
