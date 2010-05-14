module Specjour
  module Cucumber
    begin
      require 'cucumber'
      require 'cucumber/formatter/progress'

      require 'specjour/cucumber/distributed_formatter'
      require 'specjour/cucumber/final_report'
    rescue LoadError
    end
  end
end
