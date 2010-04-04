module Specjour
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
      GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)
      DRb
      Rspec::DistributedFormatter.batch_size = batch_size
      Cucumber::DistributedFormatter.batch_size = batch_size
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
          printer.send_message(:done)
          printer.send_message(:worker_summary=, {:duration => sprintf("%6f", run_time)})
          printer.close
        end
      end
    end

    protected

    def cucumber_loaded?
      !@cucumber_loaded.nil?
    end

    def printer
      @printer ||= printer_connection
    end

    def printer_connection
      Connection.new printer_uri
    end

    def run_test(test)
      if test =~ /.feature/
        set_up_cucumber unless cucumber_loaded?
        run_feature test
      else
        run_spec test
      end
    end

    def run_feature(feature)
      Kernel.puts "Running #{feature}"
      features = @step_mother.load_plain_text_features(feature)
      @cucumber_runner.visit_features(features)
    end

    def run_spec(spec)
      puts "Running #{spec}"
      options = Spec::Runner::OptionParser.parse(
        ['--format=Specjour::Rspec::DistributedFormatter', spec],
        $stderr,
        printer_connection
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
      ::Cucumber::Cli::Options.class_eval { def print_profile_information; end }
      # configuration.options.instance_variable_set(:@skip_profile_information, true)
      @step_mother = ::Cucumber::Cli::Main.step_mother
      configuration = ::Cucumber::Cli::Configuration.new
      configuration.parse! []
      @step_mother.options = configuration.options
      @step_mother.load_code_files(configuration.support_to_load)
      @step_mother.after_configuration(configuration)
      @step_mother.load_code_files(configuration.step_defs_to_load)

      formatter = Specjour::Cucumber::DistributedFormatter.new @step_mother, printer_connection, configuration.options
      @cucumber_runner = ::Cucumber::Ast::TreeWalker.new(@step_mother, [formatter])
      @step_mother.visitor = @cucumber_runner

      @cucumber_loaded = true
    end
  end
end
