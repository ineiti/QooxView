require 'helperclasses/system'

class MakeSteps
  attr_accessor :step, :status, :data, :auto_update
  include HelperClasses

  def initialize(session, wait = 0, &block)
    @block = block
    @oldstep = @step = 0
    @wait = wait
    session._s_data._make_step = self
  end

  def self.make_step(session, data = nil)
    session._s_data._make_step.make_step(session, data)
  end

  def reply
    #dputs_func
    dputs(3){"Oldstep: #{@oldstep} - #{@step}"}
    if @oldstep == @step && @step >= 0
      @step += 1
      dputs(3) { "Increasing step to #{@step}" }
    end
    @ret ||= []
    dputs(3) { "#{@ret} :: #{status.inspect} :: #{@auto_update.inspect}" }
    @ret.length == 0 and @ret = @status.to_a
    @ret += View.reply(:auto_update, @auto_update.to_i)
    dputs(3) { "ret is now #{@ret.inspect}" }
    @auto_update = nil if (@wait == 0 || @step == -1)
    dputs(3) { "Auto-update is #{@auto_update}" }
    @status = nil
    return @ret
  end

  def make_step(session, data = nil)
    #dputs_func
    dputs(3){"Oldstep in make_step: #{@oldstep}"}
    if @wait.abs > 0
      if !@thread
        dputs(3) { 'Creating new thread' }
        @thread = Thread.new {
          System.rescue_all do
            @oldstep = @step
            dputs(3) { "Calling block for step #{@step}" }
            begin
              @ret = @block.yield(session, data, @step)
            rescue LocalJumpError => e
              dputs(3) { "LocalJump: #{e.inspect}" }
              @ret = nil
            end
          end
        }
      end
      (0..@wait.abs*10).each { |i|
        dputs(4) { "Waiting #{i}" }
        sleep 0.1
        if !@thread.alive?
          dputs(3) { "Got return-value #{@ret}" }
          @thread = nil
          return reply
        end
      }
      View.reply(:auto_update, @wait) + @status.to_a
    else
      dputs(3) { "Calling block for step #{@step}" }
      begin
        @oldstep = @step
        @ret = @block.yield(session, data, @step)
      rescue LocalJumpError => e
        dputs(3) { "LocalJump: #{e.inspect}" }
        @ret = nil
      end
      reply
    end
  end
end
