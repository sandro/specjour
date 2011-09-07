module Specjour
  require 'specjour/rspec'
  require 'specjour/cucumber'

  class Worker
    include Protocol
    include SocketHelper
    attr_accessor :printer_uri
    attr_reader :project_path, :number, :task

    def initialize(options = {})
      ARGV.replace []
      $stdout = StringIO.new if options[:quiet]
      @project_path = options[:project_path]
      @number = options[:number].to_i
      @task = options[:task]
      self.printer_uri = options[:printer_uri]
      set_env_variables
      Dir.chdir(project_path)
      Specjour.load_custom_hooks
    end

    def printer_uri=(val)
      @printer_uri = URI.parse(val)
    end

    def prepare
      Configuration.prepare.call
    end

    def run_tests
      Configuration.after_fork.call
      run_times = Hash.new(0)

      while test = connection.next_test
        print_status(test)
        time = Benchmark.realtime { run_test test }
        profile(test, time)
        run_times[test_type(test)] += time
      end

      send_run_times(run_times)
      connection.send_message(:done)
    ensure
      connection.disconnect
    end

    protected

    def connection
      @connection ||= printer_connection
    end

    def printer_connection
      Connection.new printer_uri
    end

    def print_status(test)
      status = "[#{ENV['TEST_ENV_NUMBER']}] Running #{test}"
      Specjour.logger.debug status
      $PROGRAM_NAME = "specjour#{status}"
    end

    def print_time_for(test, time)
      printf "[#{ENV['TEST_ENV_NUMBER']}] Finished #{test} in %.4f\n", time
    end

    def profile(test, time)
      connection.send_message(:add_to_profiler, [test, time])
      print_time_for(test, time)
    end

    def run_test(test)
      if test_type(test) == :cucumber
        run_feature test
      else
        run_spec test
      end
    end

    def run_feature(feature)
      Specjour::Cucumber::Runner.run(feature, connection)
    end

    def run_spec(spec)
      Specjour::RSpec::Runner.run(spec, connection)
    end

    def send_run_times(run_times)
      [:rspec, :cucumber].each do |type|
        connection.send_message(:"#{type}_summary=", {:duration => sprintf("%6f", run_times[type])}) if run_times[type] > 0
      end
    end

    def test_type(test)
      test =~ /\.feature$/ ? :cucumber : :rspec
    end

    def set_env_variables
      ENV['RSPEC_COLOR'] ||= 'true'
      ENV['TEST_ENV_NUMBER'] ||= number.to_s
    end
  end
end
