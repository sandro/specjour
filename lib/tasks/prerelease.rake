desc 'tag, push gem, push to github'
task :prerelease do
  require 'specjour'
  command = %(
    git tag v#{Specjour::VERSION} &&
    rake build &&
    git push &&
    gem push pkg/specjour-#{Specjour::VERSION}.gem &&
    git push --tags
  )
  puts command
  puts %x(#{command})
end