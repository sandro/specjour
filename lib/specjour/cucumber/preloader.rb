module Specjour
  module Cucumber
    module Preloader
      def self.load(feature_file)
        configuration = ::Cucumber::Cli::Configuration.new
        configuration.parse! []
        runtime = ::Cucumber::Runtime.new(configuration)
        runtime.send :load_step_definitions
        Cucumber.runtime = runtime
      end
    end
  end
end
