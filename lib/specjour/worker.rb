module Specjour
  require 'specjour/rspec'
  require 'specjour/cucumber'

  class Worker
    include Protocol
    include SocketHelpers
    attr_accessor :printer_uri
    attr_reader :project_path, :number

    def initialize(options = {})
      @project_path = options[:project_path]
      @number = options[:number].to_i
      self.printer_uri = options[:printer_uri]
      set_env_variables
    end

    def printer_uri=(val)
      @printer_uri = URI.parse(val)
    end

    def start
      run_time = 0
      Dir.chdir(project_path)
      while test = connection.next_test
        time = Benchmark.realtime do
          run_test test
        end
        run_time += time if test =~ /_spec\.rb$/
      end
      connection.send_message(:rspec_summary=, {:duration => sprintf("%6f", run_time)})
      connection.send_message(:done)
      connection.disconnect
    end

    protected

    def connection
      @connection ||= printer_connection
    end

    def printer_connection
      Connection.new printer_uri
    end

    def run_test(test)
      puts "[#{ENV['TEST_ENV_NUMBER']}] Running #{test}"
      if test =~ /\.feature$/
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
      options = Spec::Runner::OptionParser.parse(
        ['--format=Specjour::Rspec::DistributedFormatter', spec],
        $stderr,
        connection
      )
      Spec::Runner.use options
      options.run_examples
    end

    def set_env_variables
      ENV['PREPARE_DB'] = 'true'
      ENV['RSPEC_COLOR'] = 'true'
      ENV['TEST_ENV_NUMBER'] = number.to_s
    end
  end
end
