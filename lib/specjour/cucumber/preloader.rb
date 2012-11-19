module Specjour
  module Cucumber
    module Preloader
      def self.load(output)
        Specjour.benchmark("Loading Cucumber Environment") do
          require 'cucumber' unless defined?(::Cucumber::Cli)
          cli = ::Cucumber::Cli::Main.new(['--format', 'Specjour::Cucumber::DistributedFormatter'], output)
          runtime = ::Cucumber::Runtime.new(cli.configuration)
          runtime.send :load_step_definitions
          runtime.send :fire_after_configuration_hook
          tree_walker = cli.configuration.build_tree_walker(runtime)
          runtime.visitor = tree_walker
          Cucumber.tree_walker = tree_walker
          Cucumber.configuration = cli.configuration
        end
      end
    end
  end
end
