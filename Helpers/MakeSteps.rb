class MakeSteps
  attr_accessor :step

  def initialize(session, &block)
    @block = block
    @step = 0
    @thread = nil
    session._s_data._make_step = self
  end

  def self.make_step(session, wait = 0)
    session._s_data._make_step.make_step(session, wait)
  end

  def make_step(session, wait = 0)
    dputs_func
    oldstep = @step
    if wait > 0
      if !@thread
        dputs(3) { "Creating new thread" }
        @thread = Thread.new {
          dputs(3) { "Calling block for step #{@step}" }
          @ret = @block.yield(session, @step)
        }
      end
      (0..wait*10).each { |i|
        dputs(4) { "Waiting #{i}" }
        sleep 0.1
        if !@thread.alive?
          dputs(3) { "Got return-value #{@ret}" }
          @thread = nil
          oldstep == @step and @step += 1
          return @ret
        end
      }
      nil
    else
      dputs(3) { "Calling block for step #{@step}" }
      ret = @block.yield(session, @step)
      oldstep == @step and @step += 1
      ret
    end
  end
end
