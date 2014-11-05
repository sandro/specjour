module Specjour
  module Plugin
    class RSpec < Base

      def load_application
        log "application loading from rspec plugin, #{File.expand_path("spec/spec_helper", Dir.pwd)}"
        require "rspec/core"
        ::RSpec::Core::Runner.disable_autorun!
        @output = StringIO.new
        ::RSpec.configuration.error_stream = $stderr
        ::RSpec.configuration.output_stream = @output
        ::RSpec.configuration.backtrace_exclusion_patterns << /lib\/specjour\//
        require File.expand_path("spec/spec_helper", Dir.pwd)
        @configuration_options = ::RSpec::Core::ConfigurationOptions.new(['--format=json', spec_files])
        # @configuration_options.parse_options
        @configuration_options.configure ::RSpec.configuration
        ::RSpec.configuration.load_spec_files
      rescue LoadError => e
        $stderr.puts "\n\nHEY THERE\n\n"
        $stderr.puts "#{e.class}: #{e.message}"
      end

      def after_suite
        ::RSpec.configuration.run_hook(:after, :suite)
      end

      def before_suite
        ::RSpec.configuration.run_hook(:before, :suite)
      end

      def register_tests_with_printer
        connection.register_tests rspec_examples
        # rspec_examples
        # connection.register_tests ["spec/specjour_spec.rb"]
      end

      def run_test(test)
        log "RSpec Plugin: attempting to run test #{test}"
        if /_spec\.rb/.match(test)
          run(test)
          true
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
        ::RSpec.configuration.add_formatter("json")
        ::RSpec.configuration.filter_manager = ::RSpec::Core::FilterManager.new
        path, line_number = test.split(":")
        ::RSpec.configuration.filter_manager.add_location(path, line_number.to_i)
        # ::RSpec.world.filtered_examples.clear
        Specjour.benchmark "running #{test}" do
        ::RSpec.configuration.reporter.report(0, nil) do |reporter|
          ::RSpec.world.example_groups.each do |group|
            all_examples = group.descendant_filtered_examples
            ex = find_example(all_examples)
            # p example
            if ex.any?
              all_examples.each do |example|
                if ex.include?(example)
                  def example.run(instance, reporter)
                    super
                  end
                else
                  def example.run(instance, reporter)
                    return
                  end
                end
              end
              # def ex.ordered
              #   self
              # end
              # meta = class << group; self; end
              # meta.send :define_method, :filtered_examples do
              #   ex
              # end
              # p group.filtered_examples.size
              group.run(reporter)
            end
          end
        end
        end
        @output.rewind
        data = @output.read
        if !data.empty?
          begin
            json = JSON.load(data)
          rescue
            require 'byebug'; byebug
            json = {}
          end
          # p json
          json["examples"].each do |e|
            connection.report_test(e)
          end
        end
        @output = StringIO.new
      # ensure
      #   ::RSpec.reset
        # ::RSpec.world.example_groups.clear
        # ::RSpec.configuration.filter_manager = ::RSpec::Core::FilterManager.new
        # ::RSpec.world.filtered_examples.clear
        # ::RSpec.world.inclusion_filter.clear
        # ::RSpec.world.exclusion_filter.clear
      end

      def rspec_examples
        debug spec_files
        if spec_files.any?
          filtered_examples
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
          p g.hooks
          require 'byebug'; byebug
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
        # require 'byebug'; byebug
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
        # shared_groups = ::RSpec.world.shared_example_groups.dup
        # ::RSpec.reset
        # shared_groups.each do |k,v|
        #   ::RSpec.world.shared_example_groups[k] = v
        # end
      end

    end
  end
end
