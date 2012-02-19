module Specjour
  module Cucumber
    begin
      require 'cucumber'
      require 'cucumber/formatter/progress'

      require 'specjour/cucumber/distributed_formatter'
      require 'specjour/cucumber/final_report'
      require 'specjour/cucumber/preloader'
      require 'specjour/cucumber/main_ext'
      require 'specjour/cucumber/runner'

      ::Cucumber::Cli::Options.class_eval { def print_profile_information; end }
    rescue LoadError
    end

    class << self; attr_accessor :runtime; end

  end
end
