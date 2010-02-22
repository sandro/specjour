module Specjour
  class Worker
    include DRbUndumped

    attr_accessor :project_name, :specs_to_run, :host, :number, :dispatcher_uri

    def initialize(project_path = nil)
      @project_path = project_path
    end

    def dispatcher_stdout
      @dispatcher_stdout ||= dispatcher.stdout
    end

    def hash
      @hash ||= Time.now.to_f.to_s.sub(/\./,'')
    end
    alias object_id hash

    def project_path=(name)
      @project_path ||= name
    end

    def project_path
      @project_path ||= File.join("/tmp", project_name)
    end

    def run
      Kernel.puts "Running #{specs_to_run.size} spec files..."
      pid = Process.fork do
        set_env_variables
        Dir.chdir(project_path) do
          ::Spec::Runner::CommandLine.run(
            ::Spec::Runner::OptionParser.parse(
              rspec_options,
              dispatcher.stderr,
              spec_reporter
            )
          )
        end
        Spec::Runner.options.instance_variable_set(:@examples_run, true)
        dispatcher.add_to_report spec_reporter.to_hash
        ::Kernel.exit!
      end
      Process.wait pid
      Kernel.puts "Done!"
    end

    def puts(msg='')
      dispatcher_stdout.puts msg
    end

    def print(*args)
      dispatcher_stdout.print *args
    end

    def flush
      dispatcher_stdout.flush
    end

    def tty?
      dispatcher_stdout.tty?
    end

    def spec_reporter
      @spec_reporter ||= SpecReporter.new self
    end

    def start
      drb_start
      announce_service
      Signal.trap('INT') { Kernel.puts; Kernel.puts "Shutting down worker..."; exit }
      DRb.thread.join
    end

    def drb_start
      server = DRb.start_service nil, self
      Kernel.puts "Server started at #{drb_uri}"
      at_exit { Kernel.puts 'shutting down DRb client'; DRb.stop_service }
      Timeout.timeout 1 do
        server.alive?
      end
    rescue Timeout::Error
      abort("DRb failed to load in 1 second")
    end

    def sync
      cmd "rsync -a --port=8989 #{host}::#{project_name} #{project_path}"
    end

    protected

    def rspec_options
      %W(--format=Specjour::DistributedFormatter --color) + specs_to_run
    end

    def cmd(command)
      Kernel.puts command
      system command
    end

    def dispatcher
      if @dispatcher && @dispatcher.instance_variable_get(:@uri) == dispatcher_uri
        @dispatcher
      else
        @dispatcher = DRbObject.new_with_uri dispatcher_uri
      end
    end

    def drb_uri
      @drb_uri ||= URI.parse(DRb.uri)
    end

    def announce_service
      DNSSD.register "specjour_worker_#{object_id}", "_#{drb_uri.scheme}._tcp", nil, drb_uri.port
    end

    def set_env_variables
      ENV['PREPARE_DB'] = 'true'
      if number > 1
        ENV['TEST_ENV_NUMBER'] = number.to_s
      end
    end
  end
end
