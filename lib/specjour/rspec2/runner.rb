module Specjour::Rspec::Runner
  def self.run(spec, output)
    reset
    options = ['--format=Specjour::Rspec::DistributedFormatter', spec]
    ::Rspec::Core::Runner.run options, $stderr, output
  end

  def self.reset
    ::Rspec.instance_variable_set(:@world, nil)
    ::Rspec.configuration.instance_variable_set(:@formatter, nil)
  end
end
