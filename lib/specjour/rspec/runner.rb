module Specjour::RSpec::Runner
  ::RSpec::Core::Runner::AT_EXIT_HOOK_BACKTRACE_LINE.replace "#{__FILE__}:#{__LINE__ + 3}:in `run'"
  def self.run(spec, output)
    args = ['--format=Specjour::RSpec::DistributedFormatter', spec]
    ::RSpec::Core::Runner.run args, $stderr, output
  ensure
    ::RSpec.configuration.filter_manager = ::RSpec::Core::FilterManager.new
    ::RSpec.world.filtered_examples.clear
    ::RSpec.world.inclusion_filter.clear
    ::RSpec.world.exclusion_filter.clear
    ::RSpec.world.send(:instance_variable_set, :@line_numbers, nil)
  end
end
