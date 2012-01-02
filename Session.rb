=begin
 This class represents the actual session and holds the following
 information:
 
 - "entity_name" - chosen entities
 - "id" - the actual id of the session
 - "permissions" - instance of Permission
=end

class Session
  attr_reader :id, :permissions
  @@sessions = {}
  
  # Adds a person with a session. Holds on to the belief that "person"
  # has the following attributes:
  # - permission - which holds the permissions available
  # - session_id - which will get the new id
  def initialize( p, id = nil )
    if p.session_id and @@sessions.has_key? p.session_id
      @@sessions.delete( p.session_id )
    end
    
    if ! id
      id = rand
    end
    p.session_id = @id = id.to_s
    @permissions = p.permissions
    @@sessions[@id] = self
    add_entity( p )
  end
  
  def add_entity( e )
    dputs 2, "Adding #{e.class.name.to_s} to instance variables"
    instance_variable_set( "@#{e.class.name.to_s}", e )
    self.class.send( :attr_reader, e.class.name.to_s )
  end
  
  def can_view( v )
    return Permission.can_view( @permissions, v )
  end
  
  def close
    @@session.delete( id )
  end
  
  def self.find_by_id( id )
    if @@sessions.has_key? id.to_s
      return @@sessions[id.to_s]
    else
      dputs 0, "Can't find session #{id}!"
      return nil
    end
  end
end
