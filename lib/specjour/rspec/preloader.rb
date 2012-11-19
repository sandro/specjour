class Specjour::RSpec::Preloader
  def self.load(paths=[])
    Specjour.benchmark("Loading RSpec environment") do
      require File.expand_path('spec/spec_helper', Dir.pwd)
      load_spec_files paths
    end
  end

  def self.load_spec_files(paths)
    options = ::RSpec::Core::ConfigurationOptions.new(paths)
    options.parse_options
    options.configure ::RSpec.configuration
    ::RSpec.configuration.load_spec_files
  end
end
