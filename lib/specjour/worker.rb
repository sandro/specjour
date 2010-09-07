module Specjour
  require 'specjour/rspec'
  require 'specjour/cucumber'

  class Worker
    include Protocol
    include SocketHelper
    attr_accessor :printer_uri
    attr_reader :project_path, :number, :preload_spec, :preload_feature, :task

    def initialize(options = {})
      ARGV.replace []
      $stdout = StringIO.new if options[:quiet]
      @project_path = options[:project_path]
      @number = options[:number].to_i
      @preload_spec = options[:preload_spec]
      @preload_feature = options[:preload_feature]
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
      load_app
      Configuration.prepare.call
      Kernel.exit!
    end

    def run_tests
      load_app
      Configuration.after_fork.call
      run_times = Hash.new(0)

      while test = connection.next_test
        time = Benchmark.realtime do
          run_test test
        end
        run_times[test_type(test)] += time
      end

      send_run_times(run_times)
      connection.send_message(:done)
      connection.disconnect
    end

    def start
      send task
    end

    protected

    def connection
      @connection ||= printer_connection
    end

    def load_app
      Rspec::Preloader.load(preload_spec) if preload_spec
      Cucumber::Preloader.load(preload_feature) if preload_feature
    rescue StandardError => exception
      msg = [
        "Caught exception: #{exception.class} #{exception.message}",
        "Proceeding... you may need to re-run the dispatcher."
      ]
      $stderr.puts msg.join("\n")
    end

    def printer_connection
      Connection.new printer_uri
    end

    def print_status(test)
      status = "[#{ENV['TEST_ENV_NUMBER']}] Running #{test}"
      puts status
      $PROGRAM_NAME = "specjour#{status}"
    end

    def run_test(test)
      print_status(test)
      if test_type(test) == :cucumber
        run_feature test
      else
        run_spec test
      end
    end

    def run_feature(feature)
      cli = ::Cucumber::Cli::Main.new(['--format', 'Specjour::Cucumber::DistributedFormatter', feature], connection)
      cli.execute!(::Cucumber::Cli::Main.step_mother)
    end

    def run_spec(spec)
      Specjour::Rspec::Runner.run(spec, connection)
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
