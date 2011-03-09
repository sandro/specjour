require 'rubygems'
require 'rake'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

RSpec::Core::RakeTask.new(:rcov)

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
