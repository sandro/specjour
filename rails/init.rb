require 'specjour/db_scrub'

Specjour::Configuration.after_fork = lambda do
  Specjour::DbScrub.scrub
end

Specjour::Configuration.prepare = lambda do
  Specjour::DbScrub.drop
  Specjour::DbScrub.scrub
end
