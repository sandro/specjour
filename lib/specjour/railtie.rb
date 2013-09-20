class Railtie < Rails::Railtie
  rake_tasks do
    load "tasks/specjour-create_test_dbs.rake"
  end
end