lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'specjour'

Gem::Specification.new do |s|
  s.required_rubygems_version = '>= 1.3.6'

  s.version = Specjour::VERSION

  s.name = 'specjour'

  s.authors = ['Sandro Turriate']
  s.email = 'sandro.turriate@gmail.com'
  s.homepage = 'https://github.com/sandro/specjour'
  s.summary = 'Distribute your spec suite amongst your LAN via Bonjour.'
  s.description = <<-EOD
    Specjour splits your RSpec suite across multiple machines, and multiple
    cores per machine, to run super-parallel-fast!  Also works with Cucumber.
  EOD

  s.default_executable = 'specjour'
  s.executables = ['specjour']

  s.require_path = 'lib'

  s.files = Dir.glob('lib/**/*') + %w(MIT_LICENSE README.markdown History.markdown Rakefile bin/specjour)

  s.add_runtime_dependency('dnssd', ['= 2.0.0'])
  s.add_runtime_dependency('thor', ['>= 0.14.0'])
  s.add_development_dependency('rspec', ['>= 2.12'])
  s.add_development_dependency('rr')
  s.add_development_dependency('cucumber', ['>= 1.2.1'])
  s.add_development_dependency('yard')
  s.add_development_dependency('byebug')
end
