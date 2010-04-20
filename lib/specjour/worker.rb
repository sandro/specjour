module Specjour
  require 'specjour/cucumber'

  class Worker
    include Protocol
    include SocketHelpers
    attr_accessor :printer_uri
    attr_reader :project_path, :specs_to_run, :number, :batch_size

    def initialize(project_path, printer_uri, number, batch_size)
      @project_path = project_path
      @specs_to_run = specs_to_run
      @number = number.to_i
      @batch_size = batch_size.to_i
      self.printer_uri = printer_uri
      Rspec::DistributedFormatter.batch_size = batch_size
      set_env_variables
    end

    def printer_uri=(val)
      @printer_uri = URI.parse(val)
    end

    def run
      printer.send_message(:ready)
      run_time = 0
      Dir.chdir(project_path)
      while !printer.closed? && data = printer.gets(TERMINATOR)
        test = load_object(data)
        if test
          run_time += Benchmark.realtime do
            run_test test
          end
          printer.send_message(:ready)
        else
          printer.send_message(:worker_summary=, {:duration => sprintf("%6f", run_time)})
          printer.send_message(:done)
          printer.disconnect
        end
      end
    end

    protected

    def printer
      @printer ||= printer_connection
    end

    def printer_connection
      Connection.new printer_uri
    end

    def run_test(test)
      puts "Running #{test}"
      if test =~ /\.feature$/
        run_feature test
      else
        run_spec test
      end
    end

    def run_feature(feature)
      set_up_cucumber
      cli = ::Cucumber::Cli::Main.new(['--format', 'Specjour::Cucumber::DistributedFormatter', feature], printer)
      cli.execute!(::Cucumber::Cli::Main.step_mother)
    end

    def run_spec(spec)
      options = Spec::Runner::OptionParser.parse(
        ['--format=Specjour::Rspec::DistributedFormatter', spec],
        $stderr,
        printer
      )
      Spec::Runner.use options
      options.run_examples
    end

    def set_env_variables
      ENV['PREPARE_DB'] = 'true'
      ENV['RSPEC_COLOR'] = 'true'
      ENV['TEST_ENV_NUMBER'] = number.to_s
    end

    def set_up_cucumber
      unless @cucumber_loaded
        Cucumber::DistributedFormatter.batch_size = batch_size
        ::Cucumber::Cli::Options.class_eval { def print_profile_information; end }
        @cucumber_loaded = true
      end
    end
  end
end
