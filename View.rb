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
    res = self.match(/^([A-Z][a-z]*)([A-Z]*[a-z]*)/)
    return res ? res[1, 2] : ["", ""]
  end

  def tab_name
    self.tab_parts[0]
  end

  def sub_name
    self.tab_parts[1]
  end

  def main_tab
    "#{tab_name}Tabs"
  end
end


class View < RPCQooxdooService
  attr_reader :visible, :configured, :order, :name, :is_tabs, :name_tab

  @@list = []
  @@tabs = []

  def initialize
    @visible = true
    @order = 50
    @name = self.class.name
    @debug = false
    @is_tabs = false
    @name_tab = nil
    @main_tab = nil

    if @name != 'View'
      @@list.push self
      if @name =~ /.*Tabs$/
        @name_tab = @name.tab_name
        @is_tabs = true
        @@tabs.push @name_tab
      else
        @main_tab = @name.main_tab
      end
      dputs(4) { "Initializing #{self.class.name}" }
      dputs(5) { "Total list of view-classes: #{@@list.join('::')}" }

      @layout = [[]]
      @actual = []
      @update = false
      @update_layout = true
      @auto_update = 0
      @auto_update_async = 0
      @auto_update_send_values = true
      @configured = true
      @functions_need = []
      @values_need = {}
      @functions_reject = []
      @data_class = Entities.service(@name.tab_name.pluralize_simple)

      if Entities.has_entity?(dc = @name.sub(/^[A-Z][a-z_-]*/, ''))
        dputs(3) { "Setting data-class to #{dc} for #{@name}" }
        set_data_class(dc.pluralize_simple)
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

      # Check for config of this special class
      dputs(5) { "config is #{$config.inspect}" }
      if get_config(false, :Views, self.class.name)
        @config = $config[:Views][self.class.name.to_sym]
        dputs(3) { "Writing config #{@config.inspect} for #{self.class.name}" }
        @config.each { |k, v|
          begin
            instance_variable_set("@#{k.to_s}", eval(v))
          rescue Exception => e
            instance_variable_set("@#{k.to_s}", v)
          end
          self.class.send(:attr_reader, k)
          dputs(3) { "Setting #{k} = #{v}}" }
        }
      else
        @config = nil
      end

      # Clean up eventual left-overs from a simple (or very complicated) layout
      while @layout.size > 1
        dputs(5) { "Cleaning up" }
        do_container_end
      end
      dputs(5) { "Layout is #{@layout.inspect}" }

      update_configured
    end
  end

  # Override this class to define your own layout. Use eventually
  # set_data_class
  def layout
  end

  # This method lets you set the data_class of your view. Later on this
  # will be automated by taking the first part of the view
  def set_data_class(d_c)
    dputs(3) { "Getting pointer #{d_c} for class #{@data_class}" }
    @data_class = Entities.send(d_c)
  end

  # Helper for the containers
  def do_container_start(tags)
    [*tags].each { |t|
      @layout.push []
      @actual.push t
    }
  end

  # Finish a GUI-container
  def do_container_end
    @layout[-2].push [@actual.pop, @layout.pop]
  end

  # Handle a whole GUI-container of different kind:
  # - vbox - starts a vertical box
  # - hbox - starts a horizontal box
  # - fields - starts a group of elements like buttons, labels and input-boxes
  # - group - draws a gray line around the container
  # - tabs - start a tabs-in-tab
  def do_container(tags, b)
    # The actual depth has to be kept, because the "b.call" might add additional depths,
    # for example a "fields, group" in case of an element.
    depth = @actual.length
    do_container_start(tags)
    b.call
    # Now we can undo all elements, even those perhaps added by "b.call" - close nicely
    dputs(4) { "Undoing #{@actual.length - depth} levels" }
    (@actual.length - depth).times { do_container_end }
  end

  def do_box(btype, arg, b)
    if @actual[-1] == "fields"
      dputs(0) { "Can't put a VBox or a HBox in a field!" }
      exit
    end
    do_container(arg == :nogroup ? [btype] : ['group', btype], b)
  end

  def do_boxg(btype, arg, b)
    if @actual[-1] == "fields"
      dputs(0) { "Can't put a VBox or a HBox in a field!" }
      exit
    end
    do_container(arg == :nogroup ? [btype] : ['groupw', btype], b)
  end

  # A vertical box, takes :nogroup as an argument, so it doesn't do
  # a "group" around it, and as such doesn't draw a gray line
  def gui_vbox(arg = nil, &b)
    do_box('vbox', arg, b)
  end

  # A vertical box, takes :nogroup as an argument, so it doesn't do
  # a "group" around it, and as such doesn't draw a gray line
  # Different that vbox, it grows
  def gui_vboxg(arg = nil, &b)
    do_box('vboxg', arg, b)
  end

  # A vertical box, takes :nogroup as an argument, so it doesn't do
  # a "group" around it, and as such doesn't draw a gray line
  # Different that vboxg, it grows but with limit to it's parent
  def gui_vboxgl(arg = nil, &b)
    do_box('vboxgl', arg, b)
  end

  # A horizontal box, takes :nogroup as an argument, so it doesn't do
  # a "group" around it, and as such doesn't draw a gray line
  def gui_hbox(arg = nil, &b)
    do_box('hbox', arg, b)
  end

  # A horizontal box, takes :nogroup as an argument, so it doesn't do
  # a "group" around it, and as such doesn't draw a gray line
  # Different that hbox, it grows
  def gui_hboxg(arg = nil, &b)
    do_boxg('hboxg', arg, b)
  end

  def gui_grow(&b)
    do_container('grow', b)
  end

  def gui_window(arg = nil, &b)
    do_container(["window:#{arg.to_s}"], b)
  end

  # Contains fields of same kind
  def gui_fields(arg = nil, &b)
    if arg == :noflex
      do_container('fields_noflex', b)
    else
      do_container('fields', b)
    end
  end

  # Draws a gray border around
  def gui_group(&b)
    do_container('group', b)
  end

  # Draws a gray border around and allows height-fill
  def gui_shrink(&b)
    do_container('shrink', b)
  end

  # Presents a tabs-in-tab
  def gui_tabs(parent)
    do_container_start(['tabs', parent])
    do_container_end
  end

  def show_in_field(a, args={}) # :nodoc:
    if not @actual.last =~ /^fields/
      do_container_start(%w( group fields ))
    end
    dputs(4) { "we'll show: #{a.inspect}" }
    [a].flatten.each { |v|
      dputs(4) { "Working on: #{v.dtype.inspect}: #{a.inspect}" }
      if v.dtype == 'entity'
        dputs(3) { "Showing entity #{v.inspect}" }
      end
      value = v.deep_clone
      value.args.merge!(args)
      @layout.last.push value
    }
  end

  # Shows an entity in different formats
  # - name - the internal name
  # - entity - what entity to show
  # - gui - how to display it (drop)
  # - field - what field of the entity to display
  def show_entity(name, entity, gui, field, args)
    show_add(['entity', entity], [name, gui, field, args])
  end

  # Shows an existing field
  def show_field(name, args = nil)
    @data_class.blocks.each { |k, v|
      dputs(4) { "#{k}:#{v}" }
      fields = v.select { |f| f.name == name }
      if fields.length > 0
        dputs(4) { fields.inspect }
        show_in_field fields
      end
    }
    args and show_arg(name, args)
  end

  def show_field_ro(name, args = {})
    show_field(name, {:ro => true}.merge(args))
  end

  # Shows an input-box for an existing field that will call a "match_by_" method
  # if something is entered
  def show_find(name)
    a = []
    @data_class.blocks.each { |k, v|
      a.push(*v.select { |b| b.name == name }.collect { |e|
               Value.simple(e.dtype, e.name, 'id')
             })
    }
    show_in_field a
  end

  # Shows a button, takes care about placing it correctly. Takes also
  # multiple buttons as arguments
  def show_button(*buttons)
    do_container_end if @actual.last == 'fields'
    do_container(buttons.length > 1 ? 'hbox' : 'vbox', proc {
                                                       buttons.each { |b|
                                                         #        @layout.last.push [ :button, b, b, nil ]
                                                         @layout.last.push Value.simple(:button, b)
                                                       }
                                                     }
    )
    do_container_end if @actual.last == 'group'
  end

  def show_split_button(name, menu)
    dputs(4) { "Adding a split-button #{name} with menu #{menu.inspect}" }
    do_container_end if @actual.last == 'fields'
    do_container('vbox', proc {
                         @layout.last.push Value.new([:split_button],
                                                     [name, {:menu => menu}])
                       }
    )
    do_container_end if @actual.last == 'group'
  end

  # Adds a new, general item
  def show_add(cmds, args)
    value = Value.new(cmds, args)

    case value.dtype
      when 'block'
        # Shows a block as defined in an Entities - useful if the same
        # values will be shown in different views
        show_in_field(@data_class.blocks[value.name], value.args)

      when 'block_ro'
        # as "block", but all elements are read-only
        show_in_field(@data_class.blocks[value.name], value.args)

      when 'find_text'
        # Shows an input-box for any data needed, calling "match_by_" if something is
        # entered
        show_in_field [Value.simple('id_text', name)]

      when 'htmls'
        # HTML-fields aren't under a "field", but a "group" is enough
        do_container_start 'group'
        @layout.last.push value
        do_container_end

      else
        # Simple types that pass directly
        show_in_field [value]
    end
  end

  # Adds arguments to an already existing field
  def show_arg(val, args, lay = @layout)
    lay.each { |l|
      case l.class.name
        when 'Array'
          show_arg(val, args, l)
        when 'Value'
          if l.name == val
            l.args.merge! args
          end
      end
    }
  end

  # Returns a list of the available views for a given user
  def self.rpc_list(session)
    View.reply(:list, View.list(session))
  end

  def rpc_list(session)
    dputs(5) { "rpc_list" }
    View.rpc_list(session)
  end

  def list(session)
    View.list(session)
  end

  def self.list(session, tabs = nil) # :nodoc:
    if not session
      dputs(2) { "No session given, returning empty" }
      return {:views => []}
    end
    dputs(4) { "Found user #{session.owner.inspect} for session_id #{session_id}" }
    views = []
    dputs(5) { @@list.inspect }
    @@list.each { |l|
      if l.visible and session.can_view(l.class.name) and l.configured
        dputs(5) { "Found view #{l.class.name}" }
        views.push(l)
      end
    }

    sub_tabs_only = false
    if not tabs
      # First test if we only have sub-tabs (they'll be shown seperatly)
      main_tabs = views.collect { |v|
        v.name.tab_name
      }.uniq
      dputs(4) { "Main_tabs are #{main_tabs.inspect}" }
      # Check for lonely tabs
      main_tabs.each { |t|
        vlen = views.select { |v|
          dputs(5) { "We have #{v.name}, #{v.name.tab_name} and #{t}" }
          v.name.tab_name == t
        }.length
        dputs(5) { "Calculating doubles for #{t}, found #{vlen}" }
        if vlen == 1
          dputs(3) { "Deleting tab #{t}" }
          views.delete_if { |v| v.name.tab_name == t and v.name.sub_name == "Tabs" }
        end
      }
      if main_tabs.length == 1
        # There is only one main_tab, we have to clean it
        views.delete_if { |v| v.name == "#{main_tabs[0]}Tabs" }
        sub_tabs_only = true
      end
    end
    if not sub_tabs_only
      dputs(3) { "Views before: #{views.each { |v| v.name }}" }
      views.delete_if { |l|
        tab_name = l.name.tab_name
        is_tabs_or_tab = @@tabs.index(tab_name)
        dputs(3) { "#{l.class} is visible? #{l.visible} - " +
            "configured? #{l.configured} - order is #{l.order}" }
        #dputs( 3 ){ "tabs: #{tabs.inspect} - tab_name: #{tab_name}" }
        # Either we ask specifically for all sub-tabs, but then we don't show the main-tab
        # or we don't ask for tabs and
        #  are the main-tab or
        #  are not tabs or tab at all
        not ((tab_name == tabs and not l.is_tabs) or
            (not tabs and (l.is_tabs or not is_tabs_or_tab)))
      }
      dputs(3) { "Views after: #{views.each { |v| v.name }}" }
    end
    self.list_views(views)
  end

  def self.list_views(list = @@list)
    {:views => list.select { |l| l.name != "Welcome" }.sort { |s, t|
      #dputs( 3 ){ "#{s.order} - #{t.order}" }
      #dputs( 4 ){ "#{s.name} - #{t.name}" }
      order = s.order.to_i <=> t.order.to_i
      if order == 0
        order = s.name <=> t.name
      end
      order
    }.collect { |c| [c.name, GetText._(c.name)] }
    }
  end

  def rpc_tabs_list_choice(session, args)
    dputs(4) { "args is #{args.inspect}" }
    ret = []
    if args.class == Hash
      args.keys.sort.each { |k|
        if args[k].class == Array
          dputs(3) { "Calling rpc_list_choice with #{k.inspect}" }
          ret += rpc_list_choice(session, k, args).to_a
        end
      }
    end
    dputs(3) { "ret is #{ret.inspect}" }
    ret
  end

  def rpc_tabs_show(session, args)
    rpc_show(session) +
        rpc_tabs_list_choice(session, args)
  end

  def rpc_tabs_update_view(session, args)
    rpc_update_view(session) +
        rpc_tabs_list_choice(session, args)
  end

  # Gives the GUI-elements for the active view
  def rpc_show(session)
    # user = Entities.Persons.match_by_session_id( session_id )
    # TODO: test for permission

    dputs(5) { "entered rpc_show" }
    reply("show",
          {:layout => layout_eval,
           :data_class => @data_class.class.to_s,
           :view_class => self.class.to_s}) +
        rpc_update_view(session)
  end

  def rpc_list_tabs(session)
    dputs(3) { "Showing tabs for @name" }
    reply('list', View.list(session, @name_tab))
  end

  def update_layout(session)
    return [] if not @layout
    dputs(3) { "Updating layout" }
    ret = []
    layout_recurse(@layout).each { |l|
      case l.dtype
        when /list|select|entity/
          if not l.args.has_key?(:lazy)
            values = l.to_a[3][:list_values]
            dputs(3) { "Here comes element #{l.name} with new list-value #{values.inspect}" }
            ret += reply(:empty_fields, [l.name]) +
                reply(:update, {l.name => values})
          end
      end
    }
    dputs(3) { "Reply is #{ret.inspect}" }
    ret
  end

  # Updates the layout of the form, especially the lists
  def rpc_update_view(session, args = nil)
    #    reply( 'empty', '*' ) +
    #    reply( 'update', layout_recurse( @layout ))
    ret = []
    if @update_layout
      dputs(3) { "updating layout" }
      ret += update_layout(session)
    end
    if @auto_update > 0
      dputs(3) { "auto-updating" }
      ret += reply("auto_update",
                   @auto_update * (@auto_update_send_values ? -1 : 1))
    end
    if @auto_update_async > 0
      dputs(3) { "auto-updating async" }
      ret += reply("auto_update_async",
                   @auto_update_async * (@auto_update_send_values ? -1 : 1))
    end
    if @debug
      dputs(4) { "debugging" }
      ret += reply("debug", 1)
    end
    if @update
      update = rpc_update(session)
      dputs(3) { "@update #{update.inspect}" }
      update and ret += update
    end
    if args
      dputs(3) { "Args: #{args.inspect}" }
      if args.class == Array
        args.flatten!(1)
      end
      ret += rpc_autofill(session, args)
    end
    dputs(3) { "showing: #{ret.inspect}" }
    ret
  end

  def rpc_autofill(session, args)
    dputs(3) { "args is #{args.inspect}" }
    ret = []
    args.keys.each { |a|
      if l = layout_find(a)
        dputs(3) { "found layout for #{a}" }
        ret += reply(:update, a => args[a])
      end
    }
    ret
  end

  def call_named(type, session, name, *args)
    rpc_name = "rpc_#{type}_#{name}"
    dputs(3) { "Searching for #{rpc_name}" }
    if self.respond_to? rpc_name
      dputs(3) { "Found #{rpc_name} and calling it with #{args.inspect}" }
      return self.send(rpc_name, session, args[0])
    else
      dputs(0) { "Error: Nobody listens to #{rpc_name} in " +
          "#{self.class.name.to_s} - ignoring" }
      return []
    end
  end

  # Call the children's rpc_button_name, if present
  def rpc_button(session, name, *args)
    call_named('button', session, name, *args)
  end

  # Call the children's rpc_button_name, if present
  def rpc_table(session, name, *args)
    call_named('table', session, name, *args)
  end

  # Call the children's rpc_callback_name, if present
  def rpc_callback(session, name, *args)
    call_named('callback', session, name, *args)
  end

  # Upon choice of an entry in the list
  def rpc_list_choice(session, name, data)
    if respond_to? "rpc_list_choice_#{name}"
      dputs(3) { "Calling rpc_list_choice-#{name}" }
      return send("rpc_list_choice_#{name}", session, data)
    elsif @main_tab
      dputs(3) { "Calling #{@main_tab}.rpc_list_choice" }
      mt = View.method_missing(@main_tab)
      if mt.respond_to? :rpc_list_choice_sub
        mt.rpc_list_choice_sub(session, name, data)
      else
        dputs(0) { "Error: #{@main_tab} doesn't listen to rpc_list_choice_sub and " +
            "neither does #{@name} listen to rpc_list_choice_#{name.to_s}" }
      end
    else
      dputs(0) { 'Error: Nobody listens to ' +
          "rpc_list_choice_#{name.to_s} in #{self.class.name.to_s} " +
          "- #{data.inspect}" }
    end
  end

  # Send the current values that are displayed
  def rpc_update(session)
    dputs(4) { "rpc_update" }
    reply("update", update(session))
  end

  def rpc_update_async(session)
    rpc_update(session)
  end

  # Returns the data for the fields as a hash
  def update(session)
    dputs(4) { "update" }
  end

  # Make a flat array containing the elements of the layout
  def layout_recurse(lay = @layout) # :nodoc:
    return [] if not lay
    ret = []
    lay.each { |l|
      if l.class == Array
        ret.push(*layout_recurse(l))
      elsif l.class == Value
        ret.push l
      end
    }
    ret
  end

  def layout_find(name)
    layout_recurse.find { |l| l.name.to_s == name.to_s }
  end

  def layout_eval(lay = @layout[0][0].dup)
    lay.collect { |l|
      if l.class == Value
        l.to_a
      elsif l.class == Array
        layout_eval(l)
      else
        l
      end
    }
  end

  def update_form_data(data)
    rep = {}
    not data and return rep

    d = data.to_hash
    dputs(5) { "update #{d.inspect} with layout #{@layout.inspect} - " +
        "#{layout_recurse(@layout).inspect}" }
    layout_recurse(@layout).each { |l|
      if d.has_key?(l.name)
        rep[l.name] = d[l.name]
      end
    }
    dputs(4) { "form_data #{rep.inspect}" }
    reply(:update, rep)
  end

  # Packs a command and a data in a hash. Multiple commands can be put together:
  #  reply( 'update', { :hello => "hello world" } ) +
  #  reply( 'self-update', 10 )
  def reply(cmd, data = nil)
    View.reply(cmd, data)
  end

  def self.reply(cmd, data = nil)
    [{:cmd => cmd, :data => data}]
  end

  def reply_visible(visible, element)
    View.reply_visible(visible, element)
  end

  def self.reply_visible(visible, element)
    View.reply(visible ? :unhide : :hide, element)
  end

  def reply_one_two(choice, one, two)
    View.reply_one_two(choice, one, two)
  end

  def self.reply_one_two(choice, one, two)
    View.reply_visible(choice, one) +
        View.reply_visible(!choice, two)
  end

  def reply_show_hide(show, hide)
    View.reply_show_hide(show, hide)
  end

  def self.reply_show_hide(show, hide)
    self.reply_one_two(true, show, hide)
  end

  # Standard button which just saves the entered data
  def rpc_button_save(session, data)
    reply(:update, @data_class.save_data(data))
  end

  # Standard button that cleans all fields
  def rpc_button_new(session, data)
    reply(:empty)
  end

  def rpc_button_close(session, data)
    reply(:window_hide)
  end

  # Standard search-field action to take
  def rpc_find(session, field, data)
    rep = @data_class.find(field, data)
    if not rep
      rep = {"#{field}" => data}
    end
    reply('update', rep) + rpc_update(session)
  end

  # Filters data from own Entity, so that these fields are not
  # overwritten
  def filter_from_entity(data)
    dputs(3) { data.inspect }
    if data and data.keys.length > 0
      data_only_keys = data.keys.select { |k|
        !@data_class.has_field? k
      }
      if data_only_keys
        data_only = data_only_keys.collect { |k|
          [k, data[k]]
        }
      else
        return Hash.new
      end
      Hash[*data_only.flatten(1)]
    else
      Hash.new
    end
  end

  def method_missing(cmd, *args)
    cmd_str = cmd.to_s
    dputs(5) { "Method missing: #{cmd}" }
    case cmd_str
      when /^show_/
        cmds = cmd_str.split("_")[1..-1]
        show_add(cmds, args)
      else
        super(cmd, args)
    end
  end

  def respond_to?(cmd)
    return super(cmd)
  end

  # Used to access subclasses defined in RPCQooxdoo
  def self.method_missing(m, *args)
    dputs(3) { "Searching #{m} with #{args.inspect}" }
    @@services_hash["View.#{m}"]
  end

  # Gets the request and converts the ids of the Entites back to
  # the objects they once were - which makes life much more easy... 
  def parse_request(method, session, params)
    dputs(3) { "Parsing #{params.inspect}" }
    return params if params.length == 0
    layout_recurse.each { |l|
      if params.last.has_key? l.name.to_s
        value = params.last[l.name.to_s]
        rep = l.parse(value)
        if rep
          dputs(3) { "Converted #{value} to #{rep.to_s}" }
          params.last[l.name.to_s] = rep
        end
      end
    }
    return params
  end

  def parse_reply(method, session, request)
    rep = self.send(method, session, *request)
    rep
  end

  def get_tab_members
    dputs(2) { "Getting tab members of #{@name} with #{@@list.inspect}" }
    @@list.select { |l|
      l.name =~ /^#{@name}/
    }.collect { |l|
      dputs(2) { "Collected " + l.name }
      l.name
    }
  end

  def update_configured
    if defined? ConfigBase
      functions = ConfigBase.get_functions
      @configured = true
      @functions_need.each { |f|
        if not functions.index(f)
          dputs(3) { "Rejecting because #{f} is missing" }
          @configured = false
        end
      }
      @functions_reject.each { |f|
        if functions.index(f)
          dputs(3) { "Rejecting because #{f} is here" }
          @configured = false
        end
      }
      @values_need.keys.each { |k|
        v = @values_need[k]
        dputs(3) { "Testing whether #{k.inspect} has #{v.inspect}" }
        if data = ConfigBase.data_get(k)
          dputs(3) { "Found data #{data.inspect}" }
          if data.to_s != v.to_s
            @configured = false
          end
        else
          @configured = false
        end
      }
      dputs(3) { "Configured for #{self.name} is #{@configured}" }
    end
  end

  def self.update_configured_all
    @@list.each { |l|
      dputs(4) { "Testing for view #{l.name}" }
      l.update_configured
    }
  end
end
