module Specjour
  class RsyncDaemon
    require 'fileutils'
    include SocketHelpers

    attr_reader :project_path, :project_name

    def initialize(project_path, project_name)
      @project_path = project_path
      @project_name = project_name
    end

    def config_directory
      @config_directory ||= File.join(project_path, ".specjour")
    end

    def config_file
      @config_file ||= File.join(config_directory, "rsyncd.conf")
    end

    def pid
      if File.exists?(pid_file)
        File.read(pid_file).strip.to_i
      end
    end

    def pid_file
      File.join(config_directory, "rsync_daemon.pid")
    end

    def start
      write_config
      Dir.chdir(project_path) do
        Kernel.system *command
      end
      Kernel.at_exit { stop }
    end

    def stop
      if pid
        Process.kill("TERM", pid)
        FileUtils.rm(pid_file)
      end
    end

    protected

    def write_config
      unless File.exists? config_file
        FileUtils.mkdir_p config_directory

        File.open(config_file, 'w') do |f|
          f.write config
        end
      end
    end

    def command
      ["rsync", "--daemon", "--config=#{config_file}", "--port=8989"]
    end

    def config
      <<-CONFIG
# #{Specjour::VERSION}
# Anonymous rsync daemon config for #{project_name}
#
# Serve this project with the following command:
# $ #{(command | ['--no-detach']).join(' ')}
#
# Rsync with the following command:
# $ rsync -a --port=8989 #{hostname}::#{project_name} /tmp/#{project_name}
#
use chroot = no
timeout = 20
read only = yes
pid file = ./.specjour/#{pid_file}

[#{project_name}]
  path = .
  exclude = .git* .specjour doc tmp/* log script
      CONFIG
    end
  end
end
