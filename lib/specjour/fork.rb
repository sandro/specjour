module Specjour::Fork

  module_function

  # fork, but don't run the parent's exit handlers
  # The one exit handler we lose however, is the printing out
  # of exceptions, so reincorporate that.
  def fork
    Kernel.fork do
      at_exit { exit! }
      begin
        yield
      rescue StandardError => e
        $stderr.puts "#{e.class} #{e.message}", e.backtrace
      end
    end
  end

  def fork_quietly
    fork do
      $stdout = StringIO.new
      yield
    end
  end

end
