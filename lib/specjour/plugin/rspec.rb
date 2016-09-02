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
        log "application loading from RSpec plugin"
        require "rspec/core"
        require File.expand_path("spec/spec_helper", Dir.pwd)

        ::RSpec::Core::Runner.disable_autorun!
        @output = connection
        ::RSpec.configuration.error_stream = $stderr
        ::RSpec.configuration.output_stream = @output

        if ::RSpec::Core::Version::STRING =~ /^3\./
          require "specjour/plugin/rspec_v3"
          extend Specjour::Plugin::RSpecV3
        else
          require "specjour/plugin/rspec_v2"
          extend Specjour::Plugin::RSpecV2
        end

        versioned_load_application
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
              if File.directory?(test_path)
                Dir["#{test_path}/**/*_spec.rb"]
              else
                test_path
              end
              # Dir[test_path, "#{test_path}/**/*_spec.rb"]
            end
          end.flatten.compact.uniq
        end
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

        attr_reader :formatter, :exit_status

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
