module Specjour::Rspec::Runner
  def self.run(spec, output)
    reset
    options = ['--format=Specjour::Rspec::DistributedFormatter', spec]
    ::Rspec::Core::Runner.run options, $stderr, output
  end

  def self.reset
    ::Rspec.world.instance_variable_set(:@example_groups, [])
    ::Rspec.world.instance_variable_set(:@shared_example_groups, {})
    ::Rspec.configuration.instance_variable_set(:@formatter, nil)
  end
end
