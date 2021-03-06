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
  
  def self.clear
    @@view = {}
    @@parent = {}
    @@sessions = {}
  end

  self.clear
  
  def self.list
    return @@view.keys
  end

  def self.add( name, view, parent = '' )
    @@view[ name.to_s ] = view.split(',')
    @@parent[ name.to_s ] = parent.split(',')
  end
  
  def self.views( permissions )
    #dputs_func
    dputs(5){"Permissions: #{permissions.inspect}"}
    dputs(5){"Views: #{@@view.inspect}"}
    [permissions].flatten.collect{|p|
      ret = @@view[p.to_s]
      @@parent[p.to_s] and ret += @@parent[p.to_s].collect{|a| self.views(a) }
      if not ret 
        ret = []
      end
      dputs(5){"Having #{ret.inspect}"}
      ret
    }.flatten.sort.uniq
  end

  def self.session_add( session, perm )
    dputs( 0 ){ "Deprecated - #{caller.inspect}" }
    exit
    #    dputs( 4 ){ "Adding permission for session #{session}: #{perm}" }
    #    @@sessions[session.to_s] = perm
  end

  def self.session_remove( session )
    dputs( 0 ){ "Deprecated - #{caller.inspect}" }
    exit
    #    @@sessions[session.to_s] = nil
  end

  def self.getViewParent( view )
    @@view[view].to_a.collect{|c| "view:#{c}"} +
      @@parent[view].to_a.collect{|c| "name:#{c}"}
  end

  def self.can( session, view )
    dputs( 0 ){ "Deprecated - #{caller.inspect}" }
    exit
    # If the list is not initialized, then everybody can do everything!
    if list.size == 0
      return true
    end

    dputs( 4 ){ "@@sessions is #{@@sessions.inspect}" }
    permission = @@sessions[session.to_s]
    if not permission or permission.length == 0
      permission = 'default'
    end

    self.can_view( permission, view )
  end

  def self.can_view( permission, view )
    # dputs_func
    action = view.to_s.gsub( /^View\./, '' )
    dputs( 4 ){ "Does #{permission.inspect} allow to do #{action} knowing #{@@view.inspect} and #{@@parent.inspect}" }
    if not permission or permission.length == 0
      permission = %w( default )
    end

    permission.to_a.each{|p|
      perm_list = self.getViewParent( p.to_s )
      dputs( 5 ){ "p is #{p} and perm_list is #{perm_list.inspect}" }
      perm_list.each{|pl|
        type, data = pl.split(':')
        dputs( 5 ){ "view = #{type} and data = #{data}" }
        case type
        when 'name'
          dputs( 5 ){ "Pushing #{self.getViewParent(data)}" }
          perm_list.push( *self.getViewParent( data ) )
        when 'view'
          if data
            dputs( 5 ){ "Searching #{action} - #{data.tab_name} for #{data} - #{action.class}" }
            if action =~ /^#{data}$/ or action =~ /^#{data.tab_name}Tabs$/
              dputs( 3 ){ "#{action} is allowed" }
              return true
            end
          end
        end
      }
    }

    dputs( 3 ){ "#{action} is NOT allowed" }
    return false
  end

  def self.has_role( permission, role )
    permission.to_a.each{|perm|
      dputs(4){"Testing #{perm} on #{role}"}
      return true if role.to_s =~ /^#{perm}$/
      @@parent[perm] and @@parent[perm].each{|par|
        dputs(4){"Testing parent #{par} on #{role}"}
        return true if par == role.to_s || self.has_role( par, role )
      }
    }
    dputs(4){"Nothing found for #{permission.inspect} on #{role}"}
    return false
  end

  # Get session
  def self.get_session( data )
    dputs( 0 ){ "Deprecated - #{caller.inspect}" }
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
