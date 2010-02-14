module Specjour
  class Server
    attr_reader :project_path

    def initialize
      @project_path = Rails.root.to_s
    end

    def alert_clients

    end

    def project_name
      File.basename(project_path)
    end

    def prepare
      system("rsync", *rsync_options)
    end

    protected

    def rsync_destination
      "/tmp/"
    end

    def rsync_options
      %w(-avv --delete --delete-excluded) + rsync_exclusions + [project_path, rsync_destination]
    end

    def rsync_exclusions
      %w(--exclude=.git --exclude=doc --exclude=tmp/* --exclude=public --exclude=log --exclude=script)
    end
  end

  class Client

    def sync
      "rsync -az -e 'ssh -l dev' farnsworth.local:/tmp/workbeast ."
    end

  end
end

__END__
task :specjour => :environment do
  server = Specjour::Server.new
  server.prepare
  # server.alert_clients
end

rake specjour
  Rsync to /tmp
  Tell clients to pull from /tmp
  Tell clients which specs to run
  Client runs specs
  Client reports back
