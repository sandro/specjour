module Specjour::RSpec::Runner
  ::RSpec::Core::Runner::AT_EXIT_HOOK_BACKTRACE_LINE.replace "#{__FILE__}:#{__LINE__ + 3}:in `run'"
  def self.run(spec, output)
    args = ['--format=Specjour::RSpec::DistributedFormatter', spec]
    ::RSpec::Core::Runner.run args, $stderr, output
  ensure
    ::RSpec.configuration.formatters.clear
  end
end
