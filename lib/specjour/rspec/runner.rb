module Specjour::RSpec::Runner
  def self.run(spec, output)
    args = ['--format=Specjour::RSpec::DistributedFormatter', spec]
    ::RSpec::Core::Runner.run args, $stderr, output
  ensure
    ::RSpec.configuration.formatters.clear
  end
end
