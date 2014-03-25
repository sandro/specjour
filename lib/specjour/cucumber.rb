module Specjour
  module Cucumber
    autoload :Preloader, 'specjour/cucumber/preloader'
    autoload :Runner, 'specjour/cucumber/runner'
    autoload :FinalReport, 'specjour/cucumber/final_report'
    autoload :DistributedFormatter, 'specjour/cucumber/distributed_formatter'

    class << self; attr_accessor :runtime; end

  end
end
