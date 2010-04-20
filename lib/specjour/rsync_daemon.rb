module Specjour
  class RsyncDaemon
    require 'fileutils'

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

    def start
      write_config
      system("rsync", "--daemon", "--config=#{config_file}", "--port=8989")
      at_exit { stop }
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

    def pid
      if File.exists?(pid_file)
        File.read(pid_file).strip.to_i
      end
    end

    def pid_file
      File.join(config_directory, "rsync_daemon.pid")
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
  exclude = .git* .specjour doc tmp/* log script
      CONFIG
    end
  end
end
