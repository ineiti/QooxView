# System-interaction for different flavours of Unix

module System
  extend self

  def run_str( cmd )
    %x[ #{cmd} ]
  end

  def run_bool( cmd )
    Kernel.system( cmd )
  end

  def exists?( cmd )
    run_bool( "which #{cmd} > /dev/null 2>&1")
  end
end