module Specjour::RSpec::Runner
  ::RSpec.configuration.backtrace_exclusion_patterns << %r(lib/specjour/)

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
