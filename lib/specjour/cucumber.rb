module Specjour
  module Cucumber
    begin
      require 'cucumber/formatter/progress'

      require 'specjour/cucumber/distributed_formatter'
      require 'specjour/cucumber/final_report'
      require 'specjour/cucumber/preloader'
      require 'specjour/cucumber/runner'
    rescue LoadError
    end

    class << self; attr_accessor :runtime; end

  end
end
