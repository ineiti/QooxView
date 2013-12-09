=begin
 This class represents the actual session and holds the following
 information:
 
 - "entity_name" - chosen entities
 - "id" - the actual id of the session
 - "permissions" - instance of Permission
 - "owner" - who called the session
=end

class Sessions < Entities
  def setup_data
    value_entity_person :owner, :drop, :full_name
    value_str :sid
    value_str :s_data
  end
  
  # Adds a person with a session.
  def create( owner = nil, sid = nil )
    if ! sid
      sid = rand
    end

    if owner
      if owner.session_id and old = match_by_sid( owner.session_id )
        old.delete
      end
    
      owner.session_id = sid.to_s
    end

    s = super( :owner => owner, :sid => sid.to_s, :s_data => {} )
    s.web_req = nil
    s.client_ip = nil
    return s
  end

end

class Session < Entity
  attr_accessor :web_req, :client_ip
  
  def setup_instance
    @web_req = nil
    @client_ip = nil
    self.s_data ||= {}
  end

  def can_view( v )
    dputs(3){"Owner is #{owner.inspect}"}
    return Permission.can_view( owner ? owner.permissions : nil, v )
  end
  
  def close
    self.delete
  end
end
