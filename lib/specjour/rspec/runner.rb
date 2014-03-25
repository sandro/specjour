module Specjour::RSpec::Runner
  ::RSpec.configuration.backtrace_clean_patterns << %r(lib/specjour/)
  # ::RSpec::Core::Configuration.backtrace_exclusion_patterns

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

  def self.run(spec, output)
    args = ['--format=Specjour::RSpec::DistributedFormatter', spec]
    options = ::RSpec::Core::ConfigurationOptions.new(args)
    options.parse_options
    ::RSpec::Core::CommandLine.new(options).run($stderr, output)
  ensure
    ::RSpec.world.example_groups.clear
    ::RSpec.configuration.filter_manager = ::RSpec::Core::FilterManager.new
    ::RSpec.world.filtered_examples.clear
    ::RSpec.world.inclusion_filter.clear
    ::RSpec.world.exclusion_filter.clear
  end
end
