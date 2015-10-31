module Specjour
  module Cucumber
    module Preloader
      def self.load(paths, output)
        Specjour.benchmark("Loading Cucumber Environment") do
          if defined?(::Rails) && !ENV['RAILS_ROOT']
            ENV['RAILS_ROOT'] = Rails.root.to_s # Load the current rails environment if it exists
          end
          require 'cucumber' unless defined?(::Cucumber::Cli)
          args = paths.unshift '--format', 'Specjour::Cucumber::DistributedFormatter'
          cli = ::Cucumber::Cli::Main.new(args, nil, output)

          configuration = cli.configuration
          options = configuration.instance_variable_get(:@options)
          options[:skip_profile_information] = true

          runtime = ::Cucumber::Runtime.new(configuration)
          runtime.send :load_step_definitions
          runtime.send :fire_after_configuration_hook
          Cucumber.runtime = runtime
        end
      end
    end
  end
end
