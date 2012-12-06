=begin
 This class represents the actual session and holds the following
 information:
 
 - "entity_name" - chosen entities
 - "id" - the actual id of the session
 - "permissions" - instance of Permission
 - "owner" - who called the session
=end

class Session
  attr_reader :id, :permissions, :owner
  attr_accessor :web_req
  @@sessions = {}
  
  # Adds a person with a session. Holds on to the belief that "owner"
  # has the following attributes:
  # - permission - which holds the permissions available
  # - session_id - which will get the new id
  def initialize( owner, id = nil )
    if owner.session_id and @@sessions.has_key? owner.session_id
      @@sessions.delete( owner.session_id )
    end
    
    if ! id
      id = rand
    end
    owner.session_id = @id = id.to_s
    @permissions = owner.permissions
    @@sessions[@id] = self
    @owner = owner
    @web_req = nil
  end
  
  def add_entity( e )
    dputs( 2 ){ "Adding #{e.class.name.to_s} to instance variables" }
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
      dputs( 0 ){ "Can't find session #{id}!" }
      return nil
    end
  end
end
