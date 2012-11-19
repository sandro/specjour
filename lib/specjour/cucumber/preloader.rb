module Specjour
  module Cucumber
    module Preloader
      def self.load(paths, output)
        Specjour.benchmark("Loading Cucumber Environment") do
          require 'cucumber' unless defined?(::Cucumber::Cli)
          args = paths.unshift '--format', 'Specjour::Cucumber::DistributedFormatter'
          cli = ::Cucumber::Cli::Main.new(args, output)

          configuration = cli.configuration
          options = configuration.instance_variable_get(:@options)
          options.instance_variable_set(:@skip_profile_information, true)

          runtime = ::Cucumber::Runtime.new(configuration)
          runtime.send :load_step_definitions
          runtime.send :fire_after_configuration_hook
          Cucumber.runtime = runtime
        end
      end
    end
  end
end
