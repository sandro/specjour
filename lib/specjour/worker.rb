module Specjour

  class Worker
    include Logger
    include Protocol
    include SocketHelper
    attr_accessor :printer_uri
    attr_reader :number, :options

    def initialize(options = {})
      ARGV.replace []
      @options = options
      $stdout = StringIO.new if options[:quiet]
      @number = options[:number].to_i
      set_env_variables
      Specjour.plugin_manager.send_task(:after_worker_fork)
    end

    def prepare
      Specjour.configuration.prepare.call
    end

    def run_tests
      log "Worker running tests"
      run_times = Hash.new(0)

      while test = connection.next_test
        print_status(test)
        time = Benchmark.realtime do
          Specjour.plugin_manager.send_task(:run_test, test)
        end
        # profile(test, time)
        # run_times[test_type(test)] += time
        connection.done
      end

      log "WHILE LOOP DONE"

      # send_run_times(run_times)
    rescue Exception => e
      $stderr.puts "RESCUED #{e.message}"
      $stderr.puts e.backtrace
    ensure
      log "Worker disconnecting"
      connection.disconnect
    end

    protected

    # def connection
    #   @connection ||= printer_connection
    # end

    # def printer_connection
    #   Connection.new printer_uri
    # end

    def print_status(test)
      status = "[#{ENV['TEST_ENV_NUMBER']}] Running #{test}"
      $stdout.puts status
      $PROGRAM_NAME = "specjour#{status}"
    end

    def print_time_for(test, time)
      printf "[#{ENV['TEST_ENV_NUMBER']}] Finished #{test} in %.2fs\n", time
    end

    # def profile(test, time)
    #   connection.send_message(:add_to_profiler, [test, time])
    #   print_time_for(test, time)
    # end

    # def run_test(test)
    #   if test_type(test) == :cucumber
    #     run_feature test
    #   else
    #     run_spec test
    #   end
    # end

    # def run_feature(feature)
    #   Cucumber::Runner.run(feature)
    # end

    # def run_spec(spec)
    #   RSpec::Runner.run(spec, connection)
    # end

    # def send_run_times(run_times)
    #   [:rspec, :cucumber].each do |type|
    #     connection.send_message(:"#{type}_summary=", {:duration => sprintf("%6f", run_times[type])}) if run_times[type] > 0
    #   end
    # end

    # def test_type(test)
    #   test =~ /\.feature(:\d+)?$/ ? :cucumber : :rspec
    # end

    def set_env_variables
      ENV['RSPEC_COLOR'] ||= 'true'
      ENV['TEST_ENV_NUMBER'] ||= number.to_s
    end
  end
end
