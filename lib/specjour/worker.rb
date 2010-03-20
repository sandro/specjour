module Specjour
  class Worker
    attr_accessor :dispatcher_uri
    attr_reader :project_path, :specs_to_run, :number, :batch_size

    def initialize(project_path, dispatcher_uri, number, specs_to_run, batch_size)
      @project_path = project_path
      @specs_to_run = specs_to_run
      @number = number.to_i
      @batch_size = batch_size.to_i
      self.dispatcher_uri = dispatcher_uri
    end

    def dispatcher_uri=(val)
      @dispatcher_uri = URI.parse(val)
    end

    def run
      puts "Running #{specs_to_run.size} spec files..."
      GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)
      DistributedFormatter.batch_size = batch_size
      Dir.chdir(project_path) do
        set_env_variables
        options = Spec::Runner::OptionParser.parse(
          rspec_options,
          STDERR,
          dispatcher
        )
        Spec::Runner.use options
        options.run_examples
        Spec::Runner.options.instance_variable_set(:@examples_run, true)
      end
    end

    protected

    def dispatcher
      @dispatcher ||= TCPSocket.open dispatcher_uri.host, dispatcher_uri.port
    end

    def rspec_options
      %w(--format=Specjour::DistributedFormatter) + specs_to_run
    end

    def set_env_variables
      ENV['PREPARE_DB'] = 'true'
      ENV['RSPEC_COLOR'] = 'true'
      if number > 1
        ENV['TEST_ENV_NUMBER'] = number.to_s
      else
        ENV['TEST_ENV_NUMBER'] = nil
      end
    end
  end
end
