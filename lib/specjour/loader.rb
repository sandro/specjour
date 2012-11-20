module Specjour
  class Loader
    include Protocol
    include Fork

    attr_reader :test_paths, :printer_uri, :project_path, :task, :worker_size, :worker_pids, :quiet

    def initialize(options = {})
      @options = options
      @printer_uri = options[:printer_uri]
      @test_paths = options[:test_paths]
      @worker_size = options[:worker_size]
      @task = options[:task]
      @quiet = options[:quiet]
      @project_path = options[:project_path]
      @worker_pids = []
      Dir.chdir project_path
      Specjour.load_custom_hooks
    end

    def start
      load_app
      Configuration.after_load.call
      (1..worker_size).each do |index|
        worker_pids << fork do
          Worker.new(
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

    def spec_files
      @spec_files ||= file_collector(spec_paths) do |path|
        if path == project_path
          Dir["spec/**/*_spec.rb"]
        else
          Dir["**/*_spec.rb"]
        end
      end
    end

    def feature_files
      @feature_files ||= file_collector(feature_paths) do |path|
        if path == project_path
          Dir["features/**/*.feature"]
        else
          Dir["**/*.feature"]
        end
      end
    end

    protected

    def spec_paths
      @spec_paths ||= test_paths.select {|p| p =~ /spec.*$/}
    end

    def feature_paths
      @feature_paths ||= test_paths.select {|p| p =~ /features.*$/}
    end

    def file_collector(paths, &globber)
      if spec_paths.empty? && feature_paths.empty?
        globber[project_path]
      else
        paths.map do |path|
          path = File.expand_path(path, project_path)
          if File.directory?(path)
            globber[path]
          else
            path
          end
        end.flatten.uniq
      end
    end

    def load_app
      RSpec::Preloader.load spec_files if spec_files.any?
      Cucumber::Preloader.load(feature_files, connection) if feature_files.any?
      register_tests_with_printer
    end

    def register_tests_with_printer
      tests = rspec_examples | cucumber_scenarios
      connection.send_message :tests=, tests
    end

    def rspec_examples
      if spec_files.any?
        filtered_examples
      else
        []
      end
    end

    def filtered_examples
      examples = ::RSpec.world.example_groups.map do |g|
        g.descendant_filtered_examples
      end.flatten
      locations = examples.map do |e|
        meta = e.metadata
        groups = e.example_group.parent_groups + [e.example_group]
        shared_group = groups.detect do |group|
          group.metadata[:shared_group_name]
        end
        if shared_group
          meta = shared_group.metadata[:example_group]
        end
        meta[:location]
      end
    ensure
      ::RSpec.reset
    end

    def cucumber_scenarios
      if feature_files.any?
        scenarios
      else
        []
      end
    end

    def scenarios
      Cucumber.runtime.send(:features).map do |feature|
        feature.feature_elements.map do |scenario|
          "#{feature.file}:#{scenario.instance_variable_get(:@line)}"
        end
      end.flatten
    end

    def kill_worker_processes
      signal = Specjour.interrupted? ? 'INT' : 'TERM'
      Process.kill(signal, *worker_pids) rescue Errno::ESRCH
    end

    def connection
      @connection ||= begin
        at_exit { connection.disconnect }
        Connection.new URI.parse(printer_uri)
      end
    end

  end
end
