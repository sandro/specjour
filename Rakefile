require 'rubygems'
require 'rake'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end

desc "tag, push gem, push to github"
task :prerelease do
  version = `cat VERSION`.strip
  command = %(
    git tag v#{version} &&
    rake build &&
    git push &&
    gem push pkg/specjour-#{version}.gem &&
    git push --tags
  )
  puts command
  puts %x(#{command})
end
