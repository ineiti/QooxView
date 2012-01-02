=begin rdoc
Holds all general methods to present the views. According to the name, a tree
is built, which is then presented in the web-frontend

Upon inheritance of View, the class is put into an array and as such will
be presented if the rights are correct.

The class should override the layout-method to define it's own layout.
In there the view describes how the windows shall be handled, using
VBoxes, HBoxes, entry-fields and some special class-variables:
- @update - whether to call the instance the first time it's shown
- @auto_update - at what time-interval the instance should be updated, in seconds
- @auto_update_send_values - whether the form sends the values of the fields to the
 update-method
- @data_class - the main responsible for that view - might be empty

There are three main groups of methods:
- gui_* are used to place the elements
- show_* refer to the elements being placed
- rpc_* are called whenever something important happens on the frontend
=end

# TODO: transform all show_* to be used like the value_* from Entities

require 'VTListPane.rb'

class Object
  def deep_clone
    if instance_variable_defined? :@deep_cloning and @deep_cloning
      return @deep_cloning_obj 
    end
    @deep_cloning_obj = clone
    @deep_cloning_obj.instance_variables.each do |var|
      val = @deep_cloning_obj.instance_variable_get(var)
      begin
        @deep_cloning = true
        val = val.deep_clone
      rescue TypeError
        next
      ensure
        @deep_cloning = false
      end
      @deep_cloning_obj.instance_variable_set(var, val)
    end
    deep_cloning_obj = @deep_cloning_obj
    @deep_cloning_obj = nil
    deep_cloning_obj
  end
end

class View < RPCQooxdooService
  attr_reader :visible, :order, :name
  
  @@list = []
  def initialize
    @visible = true
    @order = 50
    @name = self.class.name
    @debug = false
    
    if @name != "View"
      @@list.push self
      dputs 4, "Initializing #{self.class.name}"
      dputs 5, "Total list of view-classes: #{@@list.join('::')}"
      @data_class = nil
      @layout = [[]]
      @actual = []
      @update = false
      @update_layout = true
      @auto_update = 0
      @auto_update_send_values = true
      
      # Check for config of this special class
      if $config and $config[:views] and $config[:views][self.class.name.to_sym]
        @config = $config[:views][self.class.name.to_sym]
        dputs 3, "Writing config #{@config.inspect} for #{self.class.name}"
        @config.each{ |k, v|
          begin
            instance_variable_set( "@#{k.to_s}", eval( v ) )
          rescue Exception => e
            instance_variable_set( "@#{k.to_s}", v )            
          end
          self.class.send( :attr_reader, k )
          dputs 3, "Setting #{k} = #{v}}"
        }
      else
        @config = nil
      end
      
      # Fetch the layout of the view
      layout
      # Clean up eventual left-overs from a simple (or very complicated) layout
      while @layout.size > 1
        dputs 5, "Cleaning up"
        gui_container_end
      end
      dputs 5, "Layout is #{@layout.inspect}"
    end
  end
  
  # Override this class to define your own layout. Use eventually
  # set_data_class
  def layout
  end
  
  # This method lets you set the data_class of your view. Later on this
  # will be automated by taking the first part of the view
  def set_data_class( d_c )
    dputs 3, "Getting pointer for class #{@data_class}"
    @data_class = Entities.send( d_c )
  end
  
  # Helper for the containers
  def gui_container_start( tags )
    [*tags].each{ |t|
      @layout.push []
      @actual.push t
    }
  end
  
  # Finish a GUI-container
  def gui_container_end
    @layout[-2].push [ @actual.pop, @layout.pop ]
  end
  
  # Handle a whole GUI-container of different kind:
  # - vbox - starts a vertical box
  # - hbox - starts a horizontal box
  # - fields - starts a group of elements like buttons, labels and input-boxes
  # - group - draws a gray line around the container
  def gui_container( tags, b )
    # The actual depth has to be kept, because the "b.call" might add additional depths,
    # for example a "fields, group" in case of an element.
    depth = @actual.length
    gui_container_start( tags )
    b.call
    # Now we can undo all elements, even those perhaps added by "b.call" - close nicely
    dputs 4, "Undoing #{@actual.length - depth} levels"
     ( @actual.length - depth ).times{ gui_container_end }
  end
  
  def gui_box( btype, arg, b )
    if @actual[-1] == "fields"
      dputs 0, "Can't put a VBox or a HBox in a field!"
      exit
    end
    gui_container( arg == :nogroup ? [btype] : ['group', btype], b )
  end
  
  # A vertical box, takes :nogroup as an argument, so it doesn't do
  # a "group" around it, and as such doesn't draw a gray line
  def gui_vbox( arg = nil, &b )
    gui_box( 'vbox', arg, b )
  end
  
  # A horizontal box, takes :nogroup as an argument, so it doesn't do
  # a "group" around it, and as such doesn't draw a gray line
  def gui_hbox( arg = nil, &b )
    gui_box( 'hbox', arg, b )
  end
  
  def gui_window( arg = nil, &b )
    gui_container( ["window:#{arg.to_s}"], b )
  end
  
  # Contains fields of same kind
  def gui_fields( arg = nil, &b )
    if arg == :noflex
      gui_container( 'fields_noflex', b )
    else
      gui_container( 'fields', b )
    end
  end
  
  # Draws a gray border around
  def gui_group( &b )
    gui_container( 'group', b )
  end
  
  def show_in_field( a ) # :nodoc:
    if not @actual.last =~ /^fields/
      gui_container_start( %w( group fields ) )
    end
    dputs 5, "we'll show: #{a.inspect}"
    [a].flatten.each{ |v|
      case v
      when v.dtype == "entity"
        show_entity( *e.split(',') )
      else
        @layout.last.push v.deep_clone
      end      
    }
  end
  
  # Shows an entity in different formats
  # - name - the internal name
  # - entity - what entity to show
  # - gui - how to display it (drop)
  # - field - what field of the entity to display
  def show_entity( name, entity, gui, field )
    case gui
    when :drop
      show_in_field( Value.new( %w( list drop ), 
      [name, "Entities.#{entity}.list_#{field}" ] ) )
    else
      show_in_field( Value.simple( "text", name ) )
    end
  end
  
  # Shows an existing field
  def show_field( name )
    @data_class.blocks.each{ |k,v|  
      dputs 4, "#{k}:#{v}"
      fields = v.select{ |f| f.name == name }
      if fields.length > 0
        dputs 4, fields.inspect
        show_in_field fields
      end
    }
  end
  
  # Shows an input-box for an existing field that will call a "find_by_" method 
  # if something is entered
  def show_find( name )
    a = []
    @data_class.blocks.each{ |k,v|
      a.push(*v.select{|b| b.name == name }.collect{ |e| 
        Value.simple( e.dtype, e.name, 'id' ) 
      })
    }
    show_in_field a
  end
  
  # Shows a button, takes care about placing it correctly. Takes also
  # multiple buttons as arguments
  def show_button( *buttons )
    gui_container_end if @actual.last == "fields"
    gui_container( buttons.length > 1 ? "hbox" : "vbox", proc {
      buttons.each{|b|
        @layout.last.push [ :button, b, b, nil ]
      }
    }
    )
    gui_container_end if @actual.last == "group"
  end
  
  # Adds a new, general item
  def show_add( cmds, args )
    value = Value.new( cmds, args )
    
    case value.dtype
    when 'block'
      # Shows a block as defined in an Entities - useful if the same
      # values will be shown in different views
      show_in_field @data_class.blocks[ value.name ]
      
    when 'find_text'
      # Shows an input-box for any data needed, calling "find_by_" if something is
      # entered
      show_in_field [ Value.simple( "id_text", name ) ]
      
    when 'html'
      # HTML-fields aren't under a "field", but a "group" is enough
      gui_container_start "group"
      @layout.last.push value
      gui_container_end
      
    else
      # Simple types that pass directly
      show_in_field [ value ]
    end
  end
  
  # Adds arguments to an already existing field
  def show_arg( val, args, lay = @layout )
    lay.each{|l|
      case l.class.name
      when "Array"
        show_arg( val, args, l )
      when "Value"
        if l.name == val
          l.args.merge! args
        end
      end  
    }
  end
  
  # Returns a list of the available views for a given user
  def rpc_list( session )
    self.list( session )
  end
  
  def list( session )
    View.list( session )
  end
  
  def self.list( session ) # :nodoc:
    if not session
      dputs 2, "No session given, returning empty"
      return { :views => [] }
    end
    dputs 4, "Found user #{session.Person.login_name} for session_id #{session_id}"
    views = []
    dputs 5, @@list.inspect
    @@list.each{|l|
      dputs 5, "#{l.class} is visible? #{l.visible} - order is #{l.order}"
      if l.visible and session.can_view( l.class.name )
        views.push( l )
      end
    }
    self.list_views( views )
  end
  
  def self.list_views( list = @@list )
    { :views => list.select{|l| l.name != "Welcome" }.sort{|s,t|
        #dputs 3, "#{s.order} - #{t.order}"   
        #dputs 4, "#{s.name} - #{t.name}"   
        order = s.order.to_i <=> t.order.to_i
        if order == 0
          order = s.name <=> t.name
        end
        order
      }.collect{|c| c.name} 
    }
  end
  
  # Gives the GUI-elements for the active view
  def rpc_show( session )
    # user = Entities.Persons.find_by_session_id( session_id )
    # TODO: test for permission
    
    dputs 5, "entered rpc_show"
    reply( "show",
    { :layout => layout_eval, 
        :data_class => @data_class.class.to_s, 
        :view_class => self.class.to_s } ) +
    rpc_update_view( session )
  end
  
  def update_layout
    return [] if not @layout
    dputs 3, "Updating layout"
    ret = []
    layout_recurse(@layout).each{|l|
      if l.list.size > 0
        dputs 3, "Here comes element #{l.inspect} with new list-value #{eval( l.list )}"
        ret += reply( 'empty', [ l.name ] )
        ret += reply( 'update', { l.name => eval( l.list ) } )
      end
    }
    dputs 3, "Reply is #{ret.inspect}"
    ret
  end
  
  # Updates the layout of the form, especially the lists
  def rpc_update_view( session )
    #    reply( 'empty', '*' ) +
    #    reply( 'update', layout_recurse( @layout ))
    ret = []
    if @update
      update = rpc_update( session )
      dputs 3, "updating #{update.inspect}"
      ret += update
    end
    if @update_layout
      ret += update_layout
    end
    if @auto_update > 0
      dputs 4, "auto-updating"
      ret += reply( "auto_update", @auto_update * ( @auto_update_send_values ? -1 : 1 ) )
    end
    if @debug
      dputs 4, "debugging"
      ret += reply( "debug", 1 )
    end
    dputs 3, "showing: #{ret.inspect}"
    ret
  end
  
  def call_named( type, session, name, *args )
    rpc_name = "rpc_#{type}_#{name}"
    dputs 3, "Searching for #{rpc_name}"
    if self.respond_to? rpc_name
      dputs 3, "Found #{rpc_name} and calling it with #{args.inspect}"
      return self.send( rpc_name, session, args[0] )
    else
      return []
    end    
  end
  
  # Call the children's rpc_button_name, if present
  def rpc_button( session, name, *args )
    call_named( "button", session, name, *args )
  end
  
  # Call the children's rpc_callback_name, if present
  def rpc_callback( session, name, *args )
    call_named( "callback", session, name, *args )
  end
  
  # Upon choice of an entry in the list
  def rpc_list_choice( session, name, *args )
    dputs 3, "Got a new choice of list: #{name.inspect} - #{args.inspect}"
  end
  
  # Send the current values that are displayed
  def rpc_update( session )
    dputs 4, "rpc_update"
    reply( "update", update( session ) )
  end
  
  # Returns the data for the fields as a hash
  def update( session )
    dputs 4, "update"
    get_form_data( get_entity( session ) )
  end
  
  # Make a flat array containing the elements of the layout
  def layout_recurse( lay ) # :nodoc:
    ret = []
    lay.each{|l|
      if l.class == Array
        ret.push( *layout_recurse( l ) )
      elsif l.class == Value
        ret.push l
      end
    }
    ret
  end
  
  def layout_eval( lay = @layout[0][0].dup )
    lay.collect{|l|
      if l.class == Value
        l.to_a
      elsif l.class == Array
        layout_eval( l )
      else
        l
      end
    }
  end
  
  def get_form_data( d ) # :nodoc:
    reply = {}
    return reply if not d
    dputs 3, "update #{d.data.inspect} with layout #{@layout.inspect} - #{layout_recurse(@layout).inspect}"
    layout_recurse(@layout).each{|l|
      #      field = l.split(":")[1].to_sym
      if d.data.has_key?( l.name ) and d.data[l.name]
        reply[l.name] = d.data[l.name]
      end
    }
    dputs 4, "rpc_update #{reply.inspect}"
    reply
  end
  
  # Helper function
  def get_entity( session )
    @data_class.find_by_session_id( session.id )
  end
  
  # Packs a command and a data in a hash. Multiple commands can be put together:
  #  reply( 'update', { :hello => "hello world" } ) +
  #  reply( 'self-update', 10 )
  def reply( cmd, data = nil )
    [{ :cmd => cmd, :data => data }]
  end
  
  # Standard button which just saves the entered data
  def rpc_button_save( session, data )
    reply( 'update', @data_class.save_data( data ) )
  end
  
  # Standard button that cleans all fields
  def rpc_button_new( session, data )
    reply( 'empty' )
  end
  
  # Standard search-field action to take
  def rpc_find( session, field, data )
    rep = @data_class.find( field, data )
    if not rep
      rep = { "#{field}" => data }
    end
    reply( 'update', rep ) + rpc_update( session )
  end
  
  # Filters data from own Entity, so that these fields are not
  # overwritten
  def filter_from_entity( data )
    dputs 3, data.inspect
    if data and data.keys.length > 0
      data_only_keys = data.keys.select{|k| 
        ! @data_class.has_field? k
      }
      if data_only_keys
        data_only = data_only_keys.collect{|k| 
          [ k, data[k] ] 
        }
      else
        return Hash.new
      end
      Hash[ *data_only.flatten(1) ]
    else
      Hash.new
    end
  end
  
  def method_missing( cmd, *args )
    cmd_str = cmd.to_s
    dputs 5, "Method missing: #{cmd}"
    case cmd_str
    when /^show_/
      cmds = cmd_str.split("_")[1..-1]
      show_add( cmds, args )
    else
      super( cmd, args )
    end
  end
  
  def respond_to?( cmd )
    return super( cmd )
  end
  
  # Used to access subclasses defined in RPCQooxdoo
  def self.method_missing(m,*args)
    dputs 3, "Searching #{m} with #{args.inspect}"
    @@services_hash["View.#{m}"]
  end
end
