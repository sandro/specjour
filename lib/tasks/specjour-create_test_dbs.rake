desc 'Prepare test databases for Specjour'
namespace :specjour do
  task :create_test_dbs, :worker_size do |t, args|
    worker_size = args[:worker_size] || 8
    for index in 1..worker_size do
      ENV['TEST_ENV_NUMBER'] = index.to_s
      Rake::Task['db:create'].invoke
      Rake::Task['db:test:load'].invoke
    end
  end
end
