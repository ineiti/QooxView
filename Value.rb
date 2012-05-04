=begin
A Value is used to define a field in either an Entities or a View. It's most simple
definition is as following:

type :name

But there are other options. The full-blown syntax is:

type_flag1_flag2_StorageType :name, :arg1 => val1, arg2 => val2

with of course 0..n flags and 0..n arguments, and with or without a StorageType.
StorageType of ALL is also possible, which will put the type in every StorageType
available to the Enttiy. Used only for the _id_ so far.

The to_s method prepares a string to be sent to the Frontend. It's format is:

[ @dtype, name, string_on_screen, args ]

where string_on_screen is taken of an eventual translation-file
=end

class Value
  attr_accessor :dtype, :name, :st, :args, :list, :entity_class
  def initialize( cmds, arguments, dt = nil )
    dputs 3, "Added new: #{cmds.inspect}, #{arguments.inspect}"

    if cmds[-1] == "ALL"
    @st = cmds.pop
    else
      @st = ( StorageType.has? cmds[-1] ) ? cmds.pop : dt
    end
    @name = arguments.shift
    @dtype = cmds.shift
    @args = {}
    @list = ""

    if arguments[-1].class == Hash
      dputs 5, "Merging Hash #{arguments[-1].inspect} into #{@args.inspect}"
    @args.merge! arguments.pop
    end

    # Do some special cases
    case @dtype
    when "list"
      case cmds[0]
      when /(array|choice|drop|single)/
        @args.merge! :list_type => cmds.shift
      end
      if arguments[0]
      @list = arguments.shift
      end
    when "select"
      @list = arguments.shift
    when "entity"
      #dputs 0, "Not supported yet!"
      #exit
      @entity_class = cmds.shift.pluralize.capitalize
      @args.merge! :list_type => arguments.shift
      @show_method, @condition = arguments
    when "array"
      dputs 0, "Not yet supported!"
      exit
    when "info"
      @args.merge! :text => arguments.pop
    when "html"
      @args.merge! :text => arguments.pop
    else
    if arguments.size > 0
    dputs 0, "Arguments should be empty by now, but are #{arguments.inspect}!"
    exit
    end
    end

    cmds.each{|c|
      @args.merge! c.to_sym => true
    }
  end

  def to_a
    fe_type, fe_name, args = @dtype, @name, @args.dup
    case @dtype
    when /list|select/
      @list.size > 0 and args.merge! :list_values => eval( @list ).to_a
    when /entity/
      fe_type = "list"
      eclass = Entities.send( @entity_class )
      e_all = eclass.search_all
      values = e_all.select{|e|
        begin
          @condition.call(e) and e.respond_to? @show_method
        rescue
        false
        end
      }.collect{|e|
        [ e.send( eclass.data_field_id ).to_s, e.send( @show_method ) ]
      }
      args.merge! :list_values => values
      dputs 3, "Args for entities is #{args.inspect}"
    end
    GetText.locale = 'fr'
    dputs 3, "Going to name #{fe_name} to #{GetText._(fe_name.to_s)}"
    [ fe_type, fe_name, GetText._( fe_name.to_s ), args ]
  end

  def self.simple( dtype, name, flags = [] )
    return Value.new( [dtype] + flags.to_a, [name])
  end

  # TODO: implement this cloning instead of deep_clone from object
  def clone_later
    dputs 0, "Cloning Value!"
    v = Value.new( [@dtype], [@name] )
    v.st = @st
    v.args = @args
    v.list = @list
    return v
  end
end
