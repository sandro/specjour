module Specjour::Rspec::Runner
  def self.run(spec, output)
    reset
    args = ['--format=Specjour::Rspec::DistributedFormatter', spec]
    ::Rspec::Core::Runner.run_in_process args, $stderr, output
  end

  def self.reset
    ::Rspec.world.instance_variable_set(:@example_groups, [])
    ::Rspec.configuration.instance_variable_set(:@formatter, nil)
  end
end
