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

    def self.wants_to_quit
      if defined?(::Cucumber) && ::Cucumber.respond_to?(:wants_to_quit=)
        ::Cucumber.wants_to_quit = true
      end
    end
  end
end
