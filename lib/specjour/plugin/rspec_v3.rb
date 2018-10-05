module Specjour
  module Plugin
    module RSpecV3

      ::RSpec::Core::Formatters.register Specjour::RspecFormatter, :message, :dump_summary, :dump_profile, :stop, :close

      def versioned_load_application
        # require File.expand_path("spec/rails_helper", Dir.pwd)
        @configuration_options = ::RSpec::Core::ConfigurationOptions.new([spec_files])
        @configuration_options.configure ::RSpec.configuration
        ::RSpec.configuration.load_spec_files
      end

      def before_suite
        ::RSpec.configuration.instance_eval do
          run_suite_hooks("a `before(:suite)` hook", @before_suite_hooks)
        end
      end

      def after_suite
        ::RSpec.configuration.instance_eval do
          run_suite_hooks("an `after(:suite)` hook", @after_suite_hooks)
        end
      end

      def run(test)
        ::RSpec.configuration.reset
        ::RSpec.configuration.default_formatter = Specjour::RspecFormatter
        ::RSpec.configuration.reporter.report(1) do |reporter|
          examples_or_groups = @all_specs[test]
          examples_or_groups.each do |example_or_group|
            if example_or_group.respond_to?(:example_group_instance)
              example = example_or_group
              instance = example.example_group.new
              example.run instance, reporter
            else
              example_or_group.run(reporter)
            end
          end
        end
      end

      # recursively gather groups containing a before(:all) hook, and examples
      def gather_groups(groups)
        groups.map do |g|
          before_all_hooks = g.hooks.send(:matching_hooks_for, :before, :all, g)
          if g.metadata.has_key?(:shared_group_name)
            g
          elsif before_all_hooks.any?
            g
          else
            (g.filtered_examples || []) + gather_groups(g.children)
          end
        end.compact.flatten
      end

    end
  end
end
