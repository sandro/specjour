module Specjour
  module Cucumber
    begin
      require 'cucumber'
      require 'cucumber/formatter/progress'

      require 'specjour/cucumber/distributed_formatter'
      require 'specjour/cucumber/final_report'

      ::Cucumber::Cli::Options.class_eval { def print_profile_information; end }
    rescue LoadError
    end
  end
end
