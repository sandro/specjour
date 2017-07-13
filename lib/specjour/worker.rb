module Specjour

  class Worker
    include Logger
    include Protocol
    include SocketHelper
    attr_reader :number, :options

    def initialize(options = {})
      Specjour.trap_interrupt_with_exit
      ARGV.replace []
      @options = options
      @number = options[:number].to_i
      Specjour.configuration.worker_number = number
      ENV['TEST_ENV_NUMBER'] = Specjour.configuration.worker_number.to_s
    end

    def prepare
      Specjour.configuration.prepare.call
    end

    def run_tests
      log "Worker running tests"

      Specjour.plugin_manager.send_task(:before_suite)

      while test = connection.next_test
        print_status(test)
        time = Benchmark.realtime do
          Specjour.plugin_manager.send_task(:run_test, test)
        end
        profile(test, time)
        connection.done
      end

      Specjour.plugin_manager.send_task(:after_suite)

    rescue StandardError, ScriptError => e
      $stderr.puts "Worker RESCUED #{e.class} '#{e.message}'"
      $stderr.puts e.backtrace
      connection.error(e)
    ensure
      remove_connection
      log "Worker disconnecting #{Process.pid}"
      r = IO.popen("ps -eo pid,ppid,command | grep #{Process.pid}")
      r.each_line do |line|
        pid, ppid = line.split(" ")
        pid = pid.to_i
        ppid = ppid.to_i
        if ppid == Process.pid && pid != r.pid
          Process.kill("KILL", pid)
        end
      end
    end

    protected

    def print_status(test)
      status = "Running #{test}"
      log status
      $PROGRAM_NAME = "specjour[#{ENV["TEST_ENV_NUMBER"]}] #{status}"
    end

    def print_time_for(test, time)
      log sprintf("Finished #{test} in %.2fs\n", time)
    end

    def profile(test, time)
      connection.add_to_profiler(test, time, "#{hostname}[#{ENV["TEST_ENV_NUMBER"]}]")
      print_time_for(test, time)
    end
  end
end
