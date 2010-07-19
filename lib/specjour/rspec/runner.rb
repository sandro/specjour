module Specjour::Rspec::Runner
  def self.run(spec, output)
    options = Spec::Runner::OptionParser.parse(
      ['--format=Specjour::Rspec::DistributedFormatter', spec],
      $stderr,
      output
    )
    Spec::Runner.use options
    options.run_examples
  end
end
