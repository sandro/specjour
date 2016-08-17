module Specjour
  module Plugin
    class RSpec < Base

      FILE_RE = /_spec\.rb/

      Specjour::Configuration.make_option(:rspec_rerun)
      Specjour.configuration.rspec_rerun = true

      attr_reader :rerunner

      def initialize
        @all_specs = {}
      end

      def interrupted!
        if defined?(::RSpec)
          ::RSpec.world.wants_to_quit = true
        end
      end

      def load_application
        $stderr.puts("RSPEC Plugin loading env in #{Dir.pwd}")
        log "application loading from rspec plugin"
        require "rspec/core"
        ::RSpec::Core::Runner.disable_autorun!
        @output = connection
        ::RSpec.configuration.error_stream = $stderr
        ::RSpec.configuration.output_stream = @output
        require File.expand_path("spec/spec_helper", Dir.pwd)
        @configuration_options = ::RSpec::Core::ConfigurationOptions.new([spec_files])
        @configuration_options.parse_options
        @configuration_options.configure ::RSpec.configuration
        ::RSpec.configuration.load_spec_files
      # rescue LoadError => e
      #   $stderr.puts "\n\nCAUGHT ERROR\n\n"
      #   $stderr.puts "#{e.class}: #{e.message}"
      end

      def after_suite
        ::RSpec.configuration.run_hook(:after, :suite)
      end

      def before_suite
        ::RSpec.configuration.run_hook(:before, :suite)
      end

      def register_tests_with_printer
        connection.register_tests rspec_examples
      end

      def run_test(test)
        run(test) if FILE_RE === test
        true
      end


      def after_print_summary(formatter)
        if formatter.failures.any?
          @rerunner = ReRunner.new(formatter)
          rerunner.start
        end
      end

      def exit_status(formatter)
        if formatter.failures.any?
          rerunner.exit_status
        end
      end

      protected

      def find_example(all_examples)
        ::RSpec.configuration.filter_manager.prune all_examples
      end

      def run(test)
        path = nil
        line_number=nil
        ::RSpec.configuration.reset
        ::RSpec.configuration.add_formatter(Specjour::RspecFormatter)
        # ::RSpec.configuration.filter_manager = ::RSpec::Core::FilterManager.new
        path, line_number = test.split(":")
        # ::RSpec.configuration.filter_manager.add_location(path, line_number.to_i)
        # ::RSpec.world.filtered_examples.clear
        ::RSpec.configuration.reporter.report(1, nil) do |reporter|
          examples_or_groups = @all_specs[test]
          examples_or_groups.each do |example_or_group|
            if example_or_group.respond_to?(:example_group)
              instance = example_or_group.example_group.new
              example_or_group.run instance, reporter
            else
              example_or_group.run(reporter)
            end
          end
        end
      end

      def rspec_examples
        if spec_files.any?
          file_names_with_location
        else
          []
        end
      end

      def spec_files
        return @spec_files if instance_variable_defined?(:@spec_files)
        if Specjour.configuration.test_paths.empty?
          @spec_files = Dir["spec/**/*_spec.rb"]
        else
          @spec_files = Specjour.configuration.test_paths.map do |test_path|
            if File.basename(test_path) != Specjour.configuration.project_path
              Dir[test_path, "#{test_path}/**/*_spec.rb"]
            end
          end.flatten.compact
        end
      end

      # recursively gather groups containing a before(:all) hook, and examples
      def gather_groups(groups)
        groups.map do |g|
          before_all_hooks = g.send(:find_hook, :before, :all, nil, nil)
          if g.metadata.has_key?(:shared_group_name)
            g
          elsif before_all_hooks.any?
            g
          else
            (g.filtered_examples || []) + gather_groups(g.children)
          end
        end.compact.flatten
      end

      def file_names_with_location
        executables = gather_groups(::RSpec.world.example_groups)
        locations = executables.map do |e|
          if e.respond_to?(:examples)
            e.metadata[:example_group][:location]
          else
            if e.example_group.metadata[:shared_group_name]
              e.metadata[:example_group][:location]
            else
              e.metadata[:location]
            end
          end
        end
        locations.map.with_index do |location, i|
          @all_specs[location] ||= []
          executable = executables[i]
          @all_specs[location] << executable
        end
        locations
      end

      class ReRunner

        include Colors

        attr_reader :formatter

        def initialize(formatter)
          @formatter = formatter
          @exit_status = false
        end

        def start
          if Specjour.configuration.rspec_rerun
            rerun
          else
            print_rerun
          end
        end

        def rerun
          command = "rake db:test:prepare && #{rerun_command}"
          output.puts("Rerunning failing tests with following command:\n#{command}")
          @exit_status = system(command)
        end

        def print_rerun
          cmd = colorize(rerun_command, :red)
          output.puts "Rerun failures with this command:\n\n#{cmd}"
        end

        def rerun_command
          "rspec #{formatter.failing_test_paths.select {|t| RSpec::FILE_RE === t}.join(" ")}"
        end

        def output
          formatter.output
        end

      end

    end
  end
end
