#
# Defines which views and which blocks of that view are available
# Each user can have different Permissions, which can be
# recursive as well.
#
# A permission is either
# - an action, which is given as a ViewName.Block.Label syntax
# - a permission-name, which is resolved recursively
#
# Every "name" has a permission to
# - view: that is, display things
# - change: that is, modify the parameters
# - allow: that is, add permissions to other people

class Permission
  @@view = {}
  @@parent = {}
  @@sessions = {}

  def self.list
    return @@view.keys
  end

  def self.add( name, view, parent = '' )
    @@view[ name.to_s ] = view.split(',')
    @@parent[ name.to_s ] = parent.split(',')
  end

  def self.session_add( session, perm )
    dputs 0, "Deprecated - #{caller.inspect}"
    exit
  #    dputs 4, "Adding permission for session #{session}: #{perm}"
  #    @@sessions[session.to_s] = perm
  end

  def self.session_remove( session )
    dputs 0, "Deprecated - #{caller.inspect}"
    exit
  #    @@sessions[session.to_s] = nil
  end

  def self.getViewParent( view )
    @@view[view].to_a.collect{|c| "view:#{c}"} +
    @@parent[view].to_a.collect{|c| "name:#{c}"}
  end

  def self.can( session, view )
    dputs 0, "Deprecated - #{caller.inspect}"
    exit
    # If the list is not initialized, then everybody can do everything!
    if list.size == 0
    return true
    end

    dputs 4, "@@sessions is #{@@sessions.inspect}"
    permission = @@sessions[session.to_s]
    if not permission or permission.length == 0
      permission = "default"
    end

    self.can_view( permission, view )
  end

  def self.can_view( permission, view )
    action = view.gsub( /^View\./, '' )
    dputs 3, "Does #{permission.inspect} allow to do #{action} knowing #{@@view.inspect} and #{@@parent.inspect}"
    if not permission or permission.length == 0
      permission = %w( default )
    end
    permission.each{|p|
      perm_list = self.getViewParent( p )
      dputs 5, "p is #{p} and perm_list is #{perm_list.inspect}"
      perm_list.each{|pl|
        type, data = pl.split(':')
        dputs 5, "view = #{type} and data = #{data}"
        case type
        when "name"
          dputs 5, "Pushing #{self.getViewParent(data)}"
          perm_list.push( *self.getViewParent( data ) )
        when "view"
          if data
            dputs 5, "Searching #{action} - #{data.tab_name} for #{data} - #{action.class}"
            if action =~ /^#{data}$/ or action =~ /^#{data.tab_name}Tabs$/
              dputs 3, "#{action} is allowed"
            return true
            end
          end
        end
      }
    }
    dputs 3, "#{action} is NOT allowed"
    return false
  end

  # Get session
  def self.get_session( data )
    dputs 0, "Deprecated - #{caller.inspect}"
    exit

    if data[0] =~ /^session_id:/
      return data[0].gsub(/^session_id:/, '' )
    else
      return nil
    end
  end

  # Try to find out what the permissions are, should be changed!
  def self.which( *data )
    return ''
  end
end
