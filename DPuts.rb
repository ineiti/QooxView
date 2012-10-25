require 'thread'
require 'singleton'

module DPuts
  class DebugLock < Mutex
    include Singleton
  end
	
	def dputs_out( n, s, call )
		DebugLock.instance.synchronize do
			width = $config[:terminal_width] ? $config[:terminal_width] : 160
			width -= 30.0
			file, func = call.split(" ")
			file = file[/^.*\/([^.]*)/, 1]
			who = ( ":" + n.to_s + ":" + file.to_s + 
					func.to_s ).ljust(30, [ "X","x","*","-","."," "][n])
			lines = []
			pos = 0
			while ( pos < s.length )
				len = width
				if s.length - pos > width
					len = s.rindex( /[, .;=&>]/, pos + width )
					len and len = len - pos + 1
					if len < width / 2
						len = width
					end
				end
				lines.push s.slice( pos, len )
				pos += len
			end
			puts who + " " + lines.shift.to_s
			lines.each{|l|
				puts " " * ( 32 ) + l
			}
		end
	end
	
  def dputs(n, &s)
  		s = yield s
    if self.class.const_get( :DEBUG_LVL ) >= n
			dputs_out( n, s, caller(0)[1] )
    end
  end

  def ddputs( n, &s )
		s = yield s
		dputs_out( -n, s, caller(0)[1] )
  end

  def log_msg( mod, msg )
    return if not $config[:log]
    File.open( $config[:log], "a" ){ |f|
      str = Time.now.strftime( "%a %y.%m.%d-%H:%M:%S #{mod}: #{msg}" )
      dputs( 0 ){ "Logging #{str}" }
      f.puts str
    }
  end

end
