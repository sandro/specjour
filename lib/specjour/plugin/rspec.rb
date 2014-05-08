module Specjour
  module Plugin
    class RSpec < Base
      include Specjour::Logger
      include SocketHelper

      def load_application
        log "application loading from rspec, #{File.expand_path("spec/spec_helper", Dir.pwd)}"
        require File.expand_path("spec/spec_helper", Dir.pwd)
        options = ::RSpec::Core::ConfigurationOptions.new(spec_files)
        options.parse_options
        options.configure ::RSpec.configuration
        ::RSpec.configuration.load_spec_files
      end

      def register_tests_with_printer
        connection.register_tests rspec_examples
      end

      def run_test(test)
        log "RSpec Plugin: attempting to run test #{test}"
        if /_spec\.rb/.match(test)
          log "plugin running test #{test}"
          connection.next_test
          true
        end
      end

      protected

      def rspec_examples
        if spec_files.any?
          filtered_examples
        else
          []
        end
      end

      def spec_files
        if Specjour.configuration.test_paths.empty?
          Dir["spec/**/*_spec.rb"]
        else
          Specjour.configuration.test_paths.map do |test_path|
            if test_path =~ /_spec\.rb$/
              Dir["#{test_path}"]
            end
          end.flatten.compact
        end
      end

      # recursively gather groups containing a before(:all) hook, and examples
      def gather_groups(groups)
        groups.map do |g|
          before_all_hooks = g.send(:find_hook, :before, :all, nil, nil)
          if before_all_hooks.any?
            g
          else
            (g.filtered_examples || []) + gather_groups(g.children)
          end
        end.flatten
      end

      def filtered_examples
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
        locations
      ensure
        shared_groups = ::RSpec.world.shared_example_groups.dup
        ::RSpec.reset
        shared_groups.each do |k,v|
          ::RSpec.world.shared_example_groups[k] = v
        end
      end

    end
  end
end
