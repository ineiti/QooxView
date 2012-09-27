=begin rdoc
Interface to the AfriCompta accounting program from Markas-al-Nour. Used for the
Cash-interface.
=end

# TODO:
# - make some error-handling if no connection or if the account doesn't exist
# - port this over as a StorageType
# - make some caching for relevant attributes

require 'net/http'

class AfriCompta
  attr_reader :src, :dst, :disabled
  def initialize( src = nil, dst = nil )
    
    @disabled = false
    if ( get_config( false, :AfriCompta, :disabled ) )
      @disabled = true
      dputs 2, "AfriCompta is disabled"
      return
    end
    
		dputs 2, "Searching for #{src} - #{dst}"
    @src = Accounts.get_by_path( src )
    @dst = Accounts.get_by_path( dst )
		
		if src and not @src
			dputs 1, "Creating Account in path #{src} for source"
			@src = Accounts.create_path( src, "source" )
		end
		if dst and not @dst
			dputs 1, "Creating Account in path #{src} for destination"
			@dst = Accounts.create_path( dst, "destination" )
		end
  end
  
  # Adds a movement with an optional message. ATTENTION:
  # "credit" and "debit" are in kCFA!!
  def add_movement( value, msg = "" )
    if @src == nil or @dst == nil
      dputs 0, "Couldn't get either source or destination-account: " +
				"#{[src, dst].inspect}"
      exit 1
    end

		Movements.create( "Automatic from #{msg}", Time.now.strftime("%Y-%m-%d"), 
			value, @src, @dst )
    get_credit
  end
  
  # Gets the credit of the src-account, or any other. ATTENTION:
  # the credit is in kCFA!
  def get_credit( acc = @src )
    if @src == nil or @dst == nil
      dputs 0, "Couldn't get either source or destination-account: " +
				"#{[src, dst].inspect}"
      return 0
    end

		if acc.total
			return acc.total.to_f
		else
			return 0
		end
  end
end
