require 'specjour'

namespace :specjour do
  task :dispatch, [:project_path] do |task, args|
    args.with_defaults :project_path => Rake.original_dir
    Specjour::Dispatcher.new(args.project_path).start
  end
end

desc "Dispatch the [project_path] to listening managers"
task :specjour, [:project_path] do |task, args|
  Rake::Task['specjour:dispatch'].invoke(args[:project_path])
end
