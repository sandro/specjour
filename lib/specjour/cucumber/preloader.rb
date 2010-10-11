module Specjour
  module Cucumber
    module Preloader
      def self.load(feature_file)
        if CUCUMBER_09x
          load_09x
        else
          load_08x
        end
      end

      protected

      def self.load_08x
        cli = ::Cucumber::Cli::Main.new []
        step_mother = cli.class.step_mother

        step_mother.log = cli.configuration.log
        step_mother.options = cli.configuration.options
        step_mother.load_code_files(cli.configuration.support_to_load)
        step_mother.after_configuration(cli.configuration)
        features = step_mother.load_plain_text_features(cli.configuration.feature_files)
        step_mother.load_code_files(cli.configuration.step_defs_to_load)
      end

      def self.load_09x
        configuration = ::Cucumber::Cli::Configuration.new
        configuration.parse! []
        runtime = ::Cucumber::Runtime.new(configuration)
        runtime.send :load_step_definitions
        Cucumber.runtime = runtime
      end
    end
  end
end
