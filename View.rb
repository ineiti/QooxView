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

require 'Helpers/VTListPane.rb'



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



class String
  def tab_parts
    res = self.match( /^([A-Z][a-z]*)([A-Z]*[a-z]*)/ )
    return res ? res[1,2] : ["", ""]
  end

  def tab_name
    self.tab_parts[0]
  end

  def sub_name
    self.tab_parts[1]
  end
end



class View < RPCQooxdooService
  attr_reader :visible, :order, :name, :is_tabs, :name_tab

  @@list = []
  @@tabs = []
  def initialize
    @visible = true
    @order = 50
    @name = self.class.name
    @debug = false
    @is_tabs = false
    @name_tab = nil

    if @name != "View"
      @@list.push self
      if @name =~ /.*Tabs$/
        @name_tab = @name.tab_name
        @is_tabs = true
        @@tabs.push @name_tab
      end
      dputs( 4 ){ "Initializing #{self.class.name}" }
      dputs( 5 ){ "Total list of view-classes: #{@@list.join('::')}" }
      #@data_class = Entities.service( @name.sub( /([A-Z][a-z]*).*/, '\1' ).pluralize )
      @data_class = Entities.service( @name.tab_name.pluralize )
      @layout = [[]]
      @actual = []
      @update = false
      @update_layout = true
      @auto_update = 0
      @auto_update_send_values = true

      # Check for config of this special class
      if $config and $config[:views] and $config[:views][self.class.name.to_sym]
        @config = $config[:views][self.class.name.to_sym]
        dputs( 3 ){ "Writing config #{@config.inspect} for #{self.class.name}" }
        @config.each{ |k, v|
          begin
            instance_variable_set( "@#{k.to_s}", eval( v ) )
          rescue Exception => e
            instance_variable_set( "@#{k.to_s}", v )
          end
          self.class.send( :attr_reader, k )
          dputs( 3 ){ "Setting #{k} = #{v}}" }
        }
      else
        @config = nil
      end

      # Fetch the layout of the view
      if @is_tabs
        gui_hboxg do
          gui_vbox :nogroup do
            layout
          end
          gui_tabs @name
        end
      else
        layout
      end
      # Clean up eventual left-overs from a simple (or very complicated) layout
      while @layout.size > 1
        dputs( 5 ){ "Cleaning up" }
        do_container_end
      end
      dputs( 5 ){ "Layout is #{@layout.inspect}" }

      #if @name.gsub(/[a-z_-]/, '').length > 1
      #  set_data_class( @name.gsub )
      #end
    end
  end

  # Override this class to define your own layout. Use eventually
  # set_data_class
  def layout
  end

  # This method lets you set the data_class of your view. Later on this
  # will be automated by taking the first part of the view
  def set_data_class( d_c )
    dputs( 3 ){ "Getting pointer for class #{@data_class}" }
    @data_class = Entities.send( d_c )
  end

  # Helper for the containers
  def do_container_start( tags )
    [*tags].each{ |t|
      @layout.push []
      @actual.push t
    }
  end

  # Finish a GUI-container
  def do_container_end
    @layout[-2].push [ @actual.pop, @layout.pop ]
  end

  # Handle a whole GUI-container of different kind:
  # - vbox - starts a vertical box
  # - hbox - starts a horizontal box
  # - fields - starts a group of elements like buttons, labels and input-boxes
  # - group - draws a gray line around the container
  # - tabs - start a tabs-in-tab
  def do_container( tags, b )
    # The actual depth has to be kept, because the "b.call" might add additional depths,
    # for example a "fields, group" in case of an element.
    depth = @actual.length
    do_container_start( tags )
    b.call
    # Now we can undo all elements, even those perhaps added by "b.call" - close nicely
    dputs( 4 ){ "Undoing #{@actual.length - depth} levels" }
    ( @actual.length - depth ).times{ do_container_end }
  end

  def do_box( btype, arg, b )
    if @actual[-1] == "fields"
      dputs( 0 ){ "Can't put a VBox or a HBox in a field!" }
      exit
    end
    do_container( arg == :nogroup ? [btype] : ['group', btype], b )
  end

  # A vertical box, takes :nogroup as an argument, so it doesn't do
  # a "group" around it, and as such doesn't draw a gray line
  def gui_vbox( arg = nil, &b )
    do_box( 'vbox', arg, b )
  end

  # A vertical box, takes :nogroup as an argument, so it doesn't do
  # a "group" around it, and as such doesn't draw a gray line
  # Different that vbox, it grows
  def gui_vboxg( arg = nil, &b )
    do_box( 'vboxg', arg, b )
  end

  # A horizontal box, takes :nogroup as an argument, so it doesn't do
  # a "group" around it, and as such doesn't draw a gray line
  def gui_hbox( arg = nil, &b )
    do_box( 'hbox', arg, b )
  end

  # A horizontal box, takes :nogroup as an argument, so it doesn't do
  # a "group" around it, and as such doesn't draw a gray line
  # Different that hbox, it grows
  def gui_hboxg( arg = nil, &b )
    do_box( 'hboxg', arg, b )
  end

  def gui_grow( &b )
    do_container( 'grow', b )
  end

  def gui_window( arg = nil, &b )
    do_container( ["window:#{arg.to_s}"], b )
  end

  # Contains fields of same kind
  def gui_fields( arg = nil, &b )
    if arg == :noflex
      do_container( 'fields_noflex', b )
    else
      do_container( 'fields', b )
    end
  end

  # Draws a gray border around
  def gui_group( &b )
    do_container( 'group', b )
  end

  # Presents a tabs-in-tab
  def gui_tabs( parent )
    do_container_start( [ 'tabs', parent ] )
    do_container_end
  end

  def show_in_field( a, args={} ) # :nodoc:
    if not @actual.last =~ /^fields/
      do_container_start( %w( group fields ) )
    end
    dputs( 5 ){ "we'll show: #{a.inspect}" }
    [a].flatten.each{ |v|
      case v
      when v.dtype == "entity"
        show_entity( *e.split(',') )
      else
        value = v.deep_clone
        value.args.merge!( args )
        @layout.last.push value
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
      dputs( 4 ){ "#{k}:#{v}" }
      fields = v.select{ |f| f.name == name }
      if fields.length > 0
        dputs( 4 ){ fields.inspect }
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
    do_container_end if @actual.last == "fields"
    do_container( buttons.length > 1 ? "hbox" : "vbox", proc {
        buttons.each{|b|
          #        @layout.last.push [ :button, b, b, nil ]
          @layout.last.push Value.simple( :button, b )
        }
      }
    )
    do_container_end if @actual.last == "group"
  end
  
  def show_split_button( name, menu )
    ddputs( 4 ){"Adding a split-button #{name} with menu #{menu.inspect}"}
    do_container_end if @actual.last == "fields"
    do_container( "vbox", proc {
        @layout.last.push Value.new( [:split_button], 
          [ name, { :menu => menu } ] )
      }
    )
    do_container_end if @actual.last == "group"    
  end

  # Adds a new, general item
  def show_add( cmds, args )
    value = Value.new( cmds, args )

    case value.dtype
    when 'block'
      # Shows a block as defined in an Entities - useful if the same
      # values will be shown in different views
      show_in_field( @data_class.blocks[ value.name ], value.args )

    when 'find_text'
      # Shows an input-box for any data needed, calling "find_by_" if something is
      # entered
      show_in_field [ Value.simple( "id_text", name ) ]

    when 'htmls'
      # HTML-fields aren't under a "field", but a "group" is enough
      do_container_start "group"
      @layout.last.push value
      do_container_end

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

  def self.list( session, tabs = nil ) # :nodoc:
    if not session
      dputs( 2 ){ "No session given, returning empty" }
      return { :views => [] }
    end
    dputs( 4 ){ "Found user #{session.owner.login_name} for session_id #{session_id}" }
    views = []
    dputs( 5 ){ @@list.inspect }
    @@list.each{|l|
      if l.visible and session.can_view( l.class.name )
        views.push( l )
      end
    }

    sub_tabs_only = false
    if not tabs
      # First test if we only have sub-tabs (they'll be shown seperatly)
      main_tabs = views.collect{|v|
        v.name.tab_name
      }.uniq
      # Check for lonely tabs
      main_tabs.each{|t|
        vlen = views.select{|v| 
          dputs(5){"We have #{v.name}, #{v.name.tab_name} and #{t}"}
          v.name.tab_name == t
        }.length
        dputs(5){"Calculating doubles for #{t}, found #{vlen}"}
        if vlen == 1
          dputs(3){"Deleting tab #{t}"}
          views.delete_if{|v| v.name.tab_name == t }
        end
      }
      if main_tabs.length == 1
        # There is only one main_tab, we have to clean it
        views.delete_if{|v| v.name == "#{main_tabs[0]}Tabs" }
        sub_tabs_only = true
      end
    end
    if not sub_tabs_only
      dputs( 2 ){ "Views before: #{views.each{|v| v.name }}" }
      views.delete_if{|l|
        tab_name = l.name.tab_name
        is_tabs_or_tab = @@tabs.index( tab_name )
        dputs( 3 ){ "#{l.class} is visible? #{l.visible} - order is #{l.order}" }
        #dputs( 3 ){ "tabs: #{tabs.inspect} - tab_name: #{tab_name}" }
        # Either we ask specifically for all sub-tabs, but then we don't show the main-tab
        # or we don't ask for tabs and
        #  are the main-tab or
        #  are not tabs or tab at all
        not ( ( tab_name == tabs and not l.is_tabs ) or
            ( not tabs and ( l.is_tabs or not is_tabs_or_tab ) ) )
      }
      dputs( 2 ){ "Views after: #{views.each{|v| v.name }}" }
    end
    self.list_views( views )
  end

  def self.list_views( list = @@list )
    { :views => list.select{|l| l.name != "Welcome" }.sort{|s,t|
        #dputs( 3 ){ "#{s.order} - #{t.order}" }
        #dputs( 4 ){ "#{s.name} - #{t.name}" }
        order = s.order.to_i <=> t.order.to_i
        if order == 0
          order = s.name <=> t.name
        end
        order
      }.collect{|c| [ c.name, GetText._( c.name ) ] }
    }
  end

  def rpc_tabs_list_choice( session, args )
    if args.class == Hash
      list = ""
      args.each{|k,v|
        if v.class == Array
          list = k
        end
      }
      return rpc_list_choice( session, list, args ).to_a
    end		
  end
	
  def rpc_tabs_show( session, args )
    rpc_show( session ) + 
      rpc_tabs_list_choice( session, args )
  end

  def rpc_tabs_update_view( session, args )
    rpc_update_view( session ) +
      rpc_tabs_list_choice( session, args )
  end

  # Gives the GUI-elements for the active view
  def rpc_show( session )
    # user = Entities.Persons.find_by_session_id( session_id )
    # TODO: test for permission

    dputs( 5 ){ "entered rpc_show" }
    reply( "show",
      { :layout => layout_eval,
        :data_class => @data_class.class.to_s,
        :view_class => self.class.to_s } ) +
      rpc_update_view( session )
  end

  def rpc_list_tabs( session )
    dputs( 3 ){ "Showing tabs for @name" }
    reply( 'list', View.list( session, @name_tab ) )
  end

  def update_layout
    return [] if not @layout
    dputs( 3 ){ "Updating layout" }
    ret = []
    layout_recurse(@layout).each{|l|
      case l.dtype
      when /list|select|entity/
        values = l.to_a[3][:list_values]
        dputs( 3 ){ "Here comes element #{l.name} with new list-value #{values.inspect}" }
        ret += reply( :empty, [ l.name ] ) +
          reply( :update, { l.name => values } )
      end
    }
    dputs( 3 ){ "Reply is #{ret.inspect}" }
    ret
  end

  # Updates the layout of the form, especially the lists
  def rpc_update_view( session, args = nil )
    #    reply( 'empty', '*' ) +
    #    reply( 'update', layout_recurse( @layout ))
    ret = []
    if @update_layout
      dputs( 3 ){ "updating layout" }
      ret += update_layout
    end
    if @auto_update > 0
      dputs( 3 ){ "auto-updating" }
      ret += reply( "auto_update", @auto_update * ( @auto_update_send_values ? -1 : 1 ) )
    end
    if @debug
      dputs( 4 ){ "debugging" }
      ret += reply( "debug", 1 )
    end
    if @update
      update = rpc_update( session )
      dputs( 3 ){ "@update #{update.inspect}" }
      ret += update
    end
    if args
      dputs( 3 ){ "Args: #{args.inspect}" }
      if args.class == Array
        args.flatten!(1)
      end
      ret += rpc_autofill( session, args )
    end
    dputs( 3 ){ "showing: #{ret.inspect}" }
    ret
  end

  def rpc_autofill( session, args )
    dputs( 3 ){ "args is #{args.inspect}" }
    ret = []
    args.keys.each{|a|
      if l = layout_find( a )
        dputs( 3 ){ "found layout for #{a}" }
        ret += reply( :update, a => args[a] )
      end
    }
    ret
  end

  def call_named( type, session, name, *args )
    rpc_name = "rpc_#{type}_#{name}"
    dputs( 3 ){ "Searching for #{rpc_name}" }
    if self.respond_to? rpc_name
      dputs( 3 ){ "Found #{rpc_name} and calling it with #{args.inspect}" }
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
    dputs( 3 ){ "Got a new choice of list: #{name.inspect} - #{args.inspect}" }
  end

  # Send the current values that are displayed
  def rpc_update( session )
    dputs( 4 ){ "rpc_update" }
    reply( "update", update( session ) )
  end

  # Returns the data for the fields as a hash
  def update( session )
    dputs( 4 ){ "update" }
    get_form_data( session.owner )
  end

  # Make a flat array containing the elements of the layout
  def layout_recurse( lay = @layout ) # :nodoc:
    return [] if not lay
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

  def layout_find( name )
    layout_recurse.find{|l| l.name.to_s == name.to_s }
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
    dputs( 3 ){ "update #{d.data.inspect} with layout #{@layout.inspect} - #{layout_recurse(@layout).inspect}" }
    layout_recurse(@layout).each{|l|
      #      field = l.split(":")[1].to_sym
      if d.data.has_key?( l.name ) and d.data[l.name]
        reply[l.name] = d.data[l.name]
      end
    }
    dputs( 4 ){ "rpc_update #{reply.inspect}" }
    reply
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
    dputs( 3 ){ data.inspect }
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
    dputs( 5 ){ "Method missing: #{cmd}" }
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
    dputs( 3 ){ "Searching #{m} with #{args.inspect}" }
    @@services_hash["View.#{m}"]
  end

  def parse_request( method, session, params )
    dputs( 3 ){ "Parsing #{params.inspect}" }
    if params[1]
      layout_recurse.each{ |l|
        if params[1].has_key? l.name.to_s
          value = params[1][l.name.to_s]
          rep = l.parse( value )
          if rep
            dputs( 3 ){ "Converted #{value} to #{rep.to_s}" }
            params[1][l.name.to_s] = rep
          end
        end
      }
    end
    return params
  end

  def parse_reply( method, session, request )
    rep = self.send( method, session, *request )
    rep
  end

  def get_tab_members
    dputs( 2 ){ "Getting tab members of #{@name} with #{@@list.inspect}" }
    @@list.select{|l|
      l.name =~ /^#{@name}/
    }.collect{|l|
      dputs( 2 ){ "Collected " + l.name }
      l.name
    }
  end
end
