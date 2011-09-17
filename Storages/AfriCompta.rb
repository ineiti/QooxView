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
  attr_reader :user, :pass, :url, :src, :dst, :disabled
  def initialize( src = nil, dst = nil, user = nil, pass = nil, url = "http://localhost:3301/" )
    @user, @pass, @url = user, pass, url
    
    @disabled = false
    if ( $config[:AfriCompta] and $config[:AfriCompta][:disabled] ) or
      not pass
      @disabled = true
      dputs 2, "AfriCompta is disabled"
      return
    end
    
    @src = get_account_id( src )
    @dst = get_account_id( dst )
    
    if @src == "" or @dst == ""
      dputs 0, "Couldn't get either source or destination-account: " +
      "#{[src, dst].inspect}"
      exit 1
    end
  end
  
  # Converts a path into an account_id
  def get_account_id( path )
    post_form( "/merge/account_get_id", {:account => path})
  end
  
  # Adds a movement with an optional message. ATTENTION:
  # "credit" and "debit" are in kCFA!!
  def add_movement( credit, debit, msg = "" )
    post_form( "/movement/add/silent",
    { :credit => credit, :debit => debit, 
    :account_src => @src, :account_dst => @dst,
    :desc => "Automatic from #{msg}", 
    :date => Time.now.strftime("%d/%m/%Y") })
    get_credit
  end
  
  # Gets the credit of the src-account, or any other. ATTENTION:
  # the credit is in kCFA!
  def get_credit( acc = @src )
    dputs 4, "Asking for credit of account #{@src}"
    credit, debit, mult = JSON.parse( get_form( "/movement/get_sum/#{acc}" ) )
    dputs 4, "And got: #{[credit, debit, mult].inspect}"
    return ( debit - credit ) * mult
  end
  
  def post_form( path, hash ) # :nodoc:
    if @disabled
      dputs 2, "AfriCompta is disabled"
      return ""
    end
    dputs 5, "Starting post_form with path #{path}"
    uri = URI.parse( @url + "#{path}" )
    opt = { "user" => @user, "pass" => @pass }.merge( hash ) 
    ret = Net::HTTP.post_form( uri, opt )
    dputs 5, "Ending post_form with path #{path}, got #{ret.inspect}"
    ret.body
  end
  
  def get_form( path ) # :nodoc:
    if @disabled
      dputs 2, "AfriCompta is disabled"
      return ""
    end
    dputs 5, "Starting get_form with path #{path}"
    url = URI.parse( @url )
    dputs 5, "Finished parsing #{@url}"
    ret = Net::HTTP.get( url.host, "#{path}/#{@user},#{@pass}", url.port )
    dputs 5, "Ending get_form with path #{path} - got #{ret}"
    ret
  end
  
end
