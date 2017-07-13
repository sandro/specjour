module Specjour
  module Plugin
    module RSpecV2

      # stub out the summary stream because the specjour socket raises an error
      # when trying to handled unstructured messages
      def self.extended(klass)
        if defined?(::RSpec::Core::Formatters::DeprecationFormatter::ImmediatePrinter)
          ::RSpec::Core::Formatters::DeprecationFormatter::ImmediatePrinter.class_eval do
            def summary_stream
              $stderr
            end
          end
          ::RSpec::Core::Formatters::DeprecationFormatter::DelayedPrinter.class_eval do
            def summary_stream
              $stderr
            end
          end
        end
      end

      def versioned_load_application
        @configuration_options = ::RSpec::Core::ConfigurationOptions.new([spec_files])
        @configuration_options.parse_options
        @configuration_options.configure ::RSpec.configuration
        ::RSpec.configuration.load_spec_files
      end

      def before_suite
        ::RSpec.configuration.run_hook(:before, :suite)
      end

      def after_suite
        ::RSpec.configuration.run_hook(:after, :suite)
      end

      def run(test)
        ::RSpec.configuration.reset
        ::RSpec.configuration.add_formatter(Specjour::RspecFormatter)
        ::RSpec.configuration.reporter.report(1, nil) do |reporter|
          examples_or_groups = @all_specs[test]
          examples_or_groups.each do |example_or_group|
            if example_or_group.respond_to?(:example_group)
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

    end
  end
end
