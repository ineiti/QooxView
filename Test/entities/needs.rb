# To change this template, choose Tools | Templates
# and open the template in the editor.

class Need1s < Entities
  attr :ok
  self.needs :Need2s
  
  def setup_data
    dputs(2){"Need1s setting up"}
    @ok = Entities.is_setup?( :Need2 )
  end
end


class Need2s < Entities
  attr :ok
  
  def setup_data
    dputs(2){"Need2s setting up"}
    @ok = ! Entities.is_setup?( :Need1 )
  end
end
