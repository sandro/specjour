module Specjour
  class Dispatcher
    attr_reader :project_path

    def initialize
      @project_path = Rails.root.to_s
    end

    def alert_clients

    end

    def project_name
      File.basename(project_path)
    end

    def serve
      rsync_daemon.start
    end

    protected

    def rsync_daemon
      @rsync_daemon ||= RsyncDaemon.new(project_path, project_name)
    end
  end

  class RsyncDaemon
    require 'fileutils'

    attr_reader :project_path, :project_name
    def initialize(project_path, project_name)
      @project_path = project_path
      @project_name = project_name
    end

    def config_file
      File.join(project_path, "tmp", "rsyncd.conf")
    end

    def start
      write_config
      system("rsync", "--daemon", "--config=#{config_file}", "--port=8989")
    end

    def stop
      Process.kill("TERM", pid)
      FileUtils.rm(pid_file)
    end

    protected

    def write_config
      unless File.exists?(config_file)
        File.open(config_file, 'w') do |f|
          f.write config
        end
      end
    end

    def pid
      File.read(pid_file).strip.to_i
    end

    def pid_file
      File.join("/tmp", "#{project_name}_rsync_daemon.pid")
    end

    def config
      <<-CONFIG
# global configuration
use chroot = no
timeout = 60
read only = yes
pid file = #{pid_file}

[#{project_name}]
  path = #{project_path}
  exclude = .git* doc tmp/* public log script
      CONFIG
    end
  end

  class Worker
    attr_reader :project_path, :project_name
    def initialize(project_path, project_name)
      @project_path = project_path
      @project_name = project_name
    end

    def sync
      "rsync -a --delete --port=8989 santurimob.local::#{project_name} /tmp/#{project_name}"
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
