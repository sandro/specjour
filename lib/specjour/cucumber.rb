module Specjour
  module Cucumber
    DRb
    require 'cucumber'
    require 'cucumber/formatter/progress'
    autoload :Dispatcher, 'specjour/cucumber/dispatcher'
    autoload :DistributedFormatter, 'specjour/cucumber/distributed_formatter'
    # autoload :FinalReport, 'specjour/cucumber/final_report'
    autoload :Printer, 'specjour/cucumber/printer'
    autoload :Worker, 'specjour/cucumber/worker'
    require 'specjour/cucumber/final_report'
  end
end
