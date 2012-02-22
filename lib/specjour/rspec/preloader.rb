class Specjour::RSpec::Preloader
  def self.load(paths=[])
    $stdout.puts "Loading RSpec Environment"
    require './spec/spec_helper'
    load_spec_files paths
  end

  def self.load_spec_files(paths)
    options = ::RSpec::Core::ConfigurationOptions.new(paths)
    options.parse_options
    options.configure ::RSpec.configuration
    ::RSpec.configuration.load_spec_files
  end
end
