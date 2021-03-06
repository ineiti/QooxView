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
    value_str :last_seen
  end

  # Adds a person with a session.
  def create(owner = nil, sid = nil)
    if !sid
      sid = rand
    end

    if owner
      if owner.session_id and old = match_by_sid(owner.session_id)
        old.delete
      end

      owner.session_id = sid.to_s
    end

    s = super(owner: owner, sid: sid.to_s, s_data: {}, last_seen: Time.now.to_i)
    s.web_req = nil
    s.client_ip = nil
    return s
  end

  def loaded
    before = @data.length
    # Reject all sessions that never got opened and those who are older than one day
    @data.delete_if { |k, v|
      !v._owner || (v._last_seen && Time.now.to_i - v._last_seen.to_i > 86_400)
    }
    dputs(3) { "Cleaning up: from #{before} to #{@data.length}" }
  end

end

class Session < Entity
  attr_accessor :web_req, :client_ip

  def setup_instance
    @web_req = nil
    @client_ip = nil
    self.s_data ||= {}
  end

  def can_view(v)
    dputs(3) { "Owner is #{owner.inspect}" }
    perms = owner ? owner.permissions : nil
    return Permission.can_view(perms, v)
  end

  def close
    self.delete
  end
end
