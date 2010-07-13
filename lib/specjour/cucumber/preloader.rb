class Specjour::Cucumber::Preloader
  def self.load(feature_file)
    # preload all features
    cli = ::Cucumber::Cli::Main.new []
    step_mother = cli.class.step_mother

    step_mother.log = cli.configuration.log
    step_mother.options = cli.configuration.options
    step_mother.load_code_files(cli.configuration.support_to_load)
    step_mother.after_configuration(cli.configuration)
    features = step_mother.load_plain_text_features(cli.configuration.feature_files)
    step_mother.load_code_files(cli.configuration.step_defs_to_load)
  end
end
