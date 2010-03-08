require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "specjour"
    gem.summary = %Q{Distribute your spec suite amongst your LAN via bonjour.}
    gem.description = %Q{Distribute your spec suite amongst your LAN via bonjour.}
    gem.email = "sandro.turriate@gmail.com"
    gem.homepage = "http://github.com/sandro/specjour"
    gem.authors = ["Sandro Turriate"]
    gem.add_dependency "dnssd", "1.3.1"
    gem.add_development_dependency "rspec", "1.2.9"
    gem.add_development_dependency "yard", "0.5.3"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end

namespace(:example) do
  $:.unshift(File.dirname(__FILE__) + "/lib")
  require 'specjour'
  task :manager do
    Specjour::Manager.new.start
  end

  task :dispatcher do
    # Specjour::Dispatcher.new(Dir.pwd).start
    Specjour::Dispatcher.new('/Users/santuri/hashrocket/workbeast').start
  end
end
