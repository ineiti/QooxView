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

  def initialize(cmds, arguments, dt = nil)
    dputs(3) { "Added new: #{cmds.inspect}, #{arguments.inspect}" }

    if cmds[-1] == 'ALL'
      @st = cmds.pop
    else
      @st = (StorageType.has? cmds[-1]) ? cmds.pop : dt
    end
    @name = arguments.shift
    @dtype = cmds.shift
    @args = {}
    @list = ""
    @eclass_proxy = nil
    @list_type = nil

    if arguments[-1].class == Hash
      dputs(5) { "Merging Hash #{arguments[-1].inspect} into #{@args.inspect}" }
      @args.merge! arguments.pop
    end

    # Do some special cases
    case @dtype
      when 'list'
        case cmds[0]
          when /(array|choice|drop|single)/
            @args.merge! :list_type => (@list_type = cmds.shift)
          when /entity/
            dputs(3) { "Adding an entity with #{cmds.inspect} - #{arguments.inspect}" }
            @dtype = 'list_entity'
            cmds.shift
            @entity_class = cmds.shift.pluralize_simple.gsub(/([A-Z])/, " \\1").
                split.collect { |s| s.capitalize }.join
            @args.merge! :list_type => (@list_type = :single)
            @show_method, @condition = arguments
        end
        if arguments[0]
          @list = arguments.shift
        end
      when 'select'
        @list = arguments.shift
      when 'entity'
        # So that "courseType" gets correctly translated to
        # "CourseTypes" (mind the capital in the middle)
        @entity_class = cmds.shift.pluralize_simple.gsub(/([A-Z])/, " \\1").
            split.collect { |s| s.capitalize }.join
        @args.merge! :list_type => (@list_type = arguments.shift)
        @show_method, @condition = arguments
        if @list_type && (!cmds.index('lazy')) && @show_method == nil
          dputs(0) { "No show_method defined in #{@name} at #{caller[5].inspect}" }
          raise 'value_entity_uncomplete'
        end
      #if !@list_type
      #  dputs(0) { "No list-type for #{@name} at #{caller[5].inspect}" }
      #  raise "value_entity_uncomplete"
      #end
      when 'array'
        dputs(0) { 'Not yet supported!' }
        exit
      when 'info'
        @args.merge! :text => arguments.pop
      when 'html'
        @args.merge! :text => arguments.pop
      else
        if arguments.size > 0
          dputs(0) { "Arguments should be empty by now, but are #{arguments.inspect}!" }
          exit
        end
    end

    cmds.each { |c|
      @args.merge! c.to_sym => true
    }
  end

  def to_a(session = nil)
    fe_type, fe_name, args = @dtype, @name, @args.dup
    case @dtype.to_s
      when 'list', 'select'
        dputs(3) { "List is #{@list}" }
        @list.size > 0 and args.merge! :list_values => eval(@list).to_a
      when /entity/
        dputs(3) { "Converting -#{@name}- to array" }
        fe_type = 'list'
        values = []
        if (not args.has_key?(:lazy)) and
            ((not args.has_key?(:session)) or session)
          dputs(3) { "will search_all for #{eclass.name} in #{@name}" }
          e_all = eclass.search_all_
          values = e_all.select { |e|
            begin
              dputs(3) { "Searching whether to show #{@name}/#{e.class.name}:#{e.inspect}" }
              dputs(3) { "Condition is #{@condition.inspect}" }
              if args.has_key?(:session)
                cond = @condition ? @condition.call(e, session) : true
              else
                cond = @condition ? @condition.call(e) : true
              end
              dputs(3) { "cond #{@condition}: #{cond}" }
              method = e.respond_to? @show_method
              dputs(3) { "method #{@show_method}: #{method}" }
              cond and method
            rescue Exception => err
              dputs(0) { "Error: while trying to work #{eclass.name} with #{e.inspect}" }
              dputs(0) { "Error: and condition #{@condition.inspect}: #{err.inspect}" }
              dputs(0) { "Callstack: #{caller.inspect}" }
              false
            end
          }.collect { |e|
            [e.send(eclass.data_field_id), e.send(@show_method)]
          }.sort { |a, b|
            a[1].to_s <=> b[1].to_s
          }
          if args.has_key? :empty
            values.unshift([0, '---'])
          end
        end
        args.merge! :list_values => values
        dputs(3) { "Args for entities is #{args.inspect}" }
    end
    dputs(3) { "Going to name #{fe_name} to #{GetText._(fe_name.to_s)}" }
    [fe_type, fe_name, GetText._(fe_name.to_s), args]
  end

  def self.simple(dtype, name, flags = [])
    return Value.new([dtype] + flags.to_a, [name])
  end

  def eclass
    dputs(4) { "Asking eclass for #{self.inspect}" }
    if @dtype =~ /^(list_)*entity$/ and not @eclass_proxy
      @eclass_proxy = Entities.send(@entity_class)
    end
    return @eclass_proxy
  end

  def parse(p)
    case @dtype
      when /entity/
        dputs(3) { "parsing #{@name}: #{p.inspect}" }
        case @list_type.to_sym
          when :drop, :single, :multi
            dputs(3) { "Getting entity for #{@list_type}-#{eclass.class.inspect}-" +
                "#{p.inspect}" }
            ret = eclass.match_by(eclass.data_field_id, p[0])
            dputs(3) { "And found #{ret.inspect}" }
            if not ret and @args.has_key? :empty
              dputs(3) { "Converting nil to 0 as we're an entity_empty" }
              ret = 0
            end
            return ret
          else
            dputs(0) { "List-type #{@list_type} not supported yet in " +
                "#{@name}::#{@list_type}!" }
            return nil
        end
    end
  end

  # TODO: implement this cloning instead of deep_clone from object
  def clone_later
    dputs(0) { 'Cloning Value!' }
    v = Value.new([@dtype], [@name])
    v.st = @st
    v.args = @args
    v.list = @list
    return v
  end
end
