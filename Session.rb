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
  
  def initialize( perm )
    @id = rand
    @permissions = perm
    @@sessions[id] = self
  end
  
  def add_entity( e )
    dputs 2, "Adding #{e.class.name.to_s} to instance variables"
    instance_variable_set( "@#{e.class.name.to_s}", e )
    self.class.send( :attr_reader, e.class.name.to_s )
  end
  
  def self.find_by_id( id )
    if @@sessions.has_key? id
      return @@sessions[id]
    else
      dputs 0, "Can't find session #{id}!"
      return nil
    end
  end
  
  # Adds a person with a session. Holds on to the belief that "person"
  # has the following attributes:
  # - permission - which holds the permissions available
  # - session_id - which will get the new id
  def self.add( p )
    dputs 2, "Adding new session for #{p.name}"
    ns = Session.new( p.permissions )
    dputs 2, "Adding entity"
    ns.add_entity( p )
    dputs 2, "Setting sid to #{ns.id}"
    p.session_id = ns.id
    ns
  end
end