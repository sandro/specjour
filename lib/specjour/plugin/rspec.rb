module Specjour
  module Plugin
    class RSpec < Base

      FILE_RE = /_spec\.rb/

      def interrupted!
        if defined?(::RSpec)
          ::RSpec.wants_to_quit = true
        end
      end

      def load_application
        $stderr.puts("RSPEC Plugin loading env in #{Dir.pwd}")
        log "application loading from rspec plugin, #{File.expand_path("spec/spec_helper", Dir.pwd)}"
        require "rspec/core"
        ::RSpec::Core::Runner.disable_autorun!
        # @output = StringIO.new
        @output = connection
        ::RSpec.configuration.error_stream = $stderr
        ::RSpec.configuration.output_stream = @output
        require File.expand_path("spec/spec_helper", Dir.pwd)
        @configuration_options = ::RSpec::Core::ConfigurationOptions.new([spec_files])
        @configuration_options.parse_options
        @configuration_options.configure ::RSpec.configuration
        ::RSpec.configuration.load_spec_files
        @all_specs = {}
      rescue LoadError => e
        $stderr.puts "\n\nCAUGHT ERROR\n\n"
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
        # log "RSpec Plugin: attempting to run test #{test}"
        # if FILE_RE.match(test)
          run(test)
          true
        # end
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
        ::RSpec.configuration.filter_manager = ::RSpec::Core::FilterManager.new
        path, line_number = test.split(":")
        ::RSpec.configuration.filter_manager.add_location(path, line_number.to_i)
        ::RSpec.world.filtered_examples.clear
        ::RSpec.configuration.reporter.report(1, nil) do |reporter|
          examples_or_groups = @all_specs[test]
          examples_or_groups.each do |example_or_group|
            if example_or_group.respond_to?(:example_group)
              instance = example_or_group.example_group.new
              example_or_group.run instance, reporter
              # example_or_group.example_group.run(reporter)
            else
              example_or_group.run(reporter)
            end
          end

          # ::RSpec.world.example_groups.each do |group|
            # p "GROUP MAYBE #{group.display_name}"
            # if group.descendant_filtered_examples.any?
              # p "GROUP YES"
              # group.run(reporter)
            # end
            # p "GROUP DONE"
          # end
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
          # if executable.respond_to?(:example_group)
          #   # if @all_specs[location].empty?
          #   #   @all_specs[location] << executable
          #   # else
          #   group_missing = @all_specs[location].none? do |exec|
          #     exec.example_group == executable.example_group
          #   end
          #   group_missing && @all_specs[location] << executable
          # else
            @all_specs[location] << executable
          # end
        end
        locations
      # ensure
        # shared_groups = ::RSpec.world.shared_example_groups.dup
        # ::RSpec.reset
        # shared_groups.each do |k,v|
        #   ::RSpec.world.shared_example_groups[k] = v
        # end
      end

    end
  end
end
            # group.descendants.each {|g| g.instance_variable_set(:@descendant_filtered_examples, nil)}

            # group.descendants.each do |g|
            #   filtered = group.filtered_examples
            #   $stderr.puts filtered.inspect
            #   g.run(reporter)
            # end

            # all_examples = group.descendant_filtered_examples
            # ex = find_example(all_examples)
            # $stderr.puts group.inspect
            # $stderr.puts ex.first.example_group.inspect
            # $stderr.puts ex.size.inspect
            # if ex.any?
            #   log "HAVE EX"
            #   all_examples.each do |example|
            #     if ex.include?(example)
            #       def example.run(instance, reporter)
            #         $stderr.puts "INCLUDES"
            #         super
            #       end
            #     else
            #       def example.run(instance, reporter)
            #         $stderr.puts "EXCLUDES"
            #         return
            #       end
            #     end
            #   end
              # def ex.ordered
              #   self
              # end
              # meta = class << group; self; end
              # meta.send :define_method, :filtered_examples do
              #   ex
              # end
              # p group.filtered_examples.size
              # group.run(reporter)
              # if ex.size > 0
                # ex.first.example_group.run(reporter)
              # end
        # @output.rewind
        # if @output.size > 0
        #   begin
        #     json = JSON.load(@output)
        #   rescue
        #     json = {}
        #   end
        #   # p json
        #   json["examples"].each do |e|
        #     connection.report_test(e)
        #   end
        # end
        # @output.reopen("")
      # ensure
        # ::RSpec.reset
        # ::RSpec.world.example_groups.clear
        # ::RSpec.configuration.filter_manager = ::RSpec::Core::FilterManager.new
        # ::RSpec.world.filtered_examples.clear
        # ::RSpec.world.inclusion_filter.clear
        # ::RSpec.world.exclusion_filter.clear
