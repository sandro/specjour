module Specjour
  class Loader

    attr_reader :printer_uri, :preload_spec, :preload_feature, :task, :worker_size, :worker_pids, :quiet

    def initialize(options = {})
      @options = options
      @printer_uri = options[:printer_uri]
      @preload_spec = options[:preload_spec]
      @preload_feature = options[:preload_feature]
      @worker_size = options[:worker_size]
      @task = options[:task]
      @quiet = options[:quiet]
      @worker_pids = []
      Dir.chdir options[:project_path]
    end

    def start
      load_app
      Configuration.after_load.call
      (1..worker_size).each do |index|
        worker_pids << fork do
          # at_exit { exit! }
          w = Worker.new(
            :number => index,
            :printer_uri => printer_uri,
            :quiet => quiet
          ).send(task)
        end
      end
      Process.waitall
    ensure
      kill_worker_processes
    end

    def load_app
      RSpec::Preloader.load(preload_spec) if preload_spec
      Cucumber::Preloader.load(preload_feature) if preload_feature
    end

    def kill_worker_processes
      if Specjour.interrupted?
        Process.kill('INT', *worker_pids) rescue Errno::ESRCH
      else
        Process.kill('TERM', *worker_pids) rescue Errno::ESRCH
      end
    end
  end
end
