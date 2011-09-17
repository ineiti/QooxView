class Welcome < View

  attr_reader :need_pass, :hide_pass
  
  def rpc_login( sid, login_name, password )
    person = Entities.Persons.find_by_login_name( login_name )
    dputs 3, "Found login #{person.inspect} for #{login_name}"
    if person and password == person.password then
      person.session_id = sid
      Permission.session_add( person.session_id, person.permissions )
      return person.to_hash
    else
      return nil
    end
  end
end
