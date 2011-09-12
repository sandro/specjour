module Specjour
  class RsyncDaemon
    require 'fileutils'
    include SocketHelper

    # Corresponds to the version of specjour that changed the configuration
    # file.
    CONFIG_VERSION = "0.3.0.rc8".freeze
    CONFIG_FILE_NAME = "rsyncd.conf"
    PID_FILE_NAME = "rsyncd.pid"

    attr_reader :project_path, :project_name, :port

    def initialize(project_path, project_name, port)
      @project_path = project_path
      @project_name = project_name
      @port = port
    end

    def config_directory
      @config_directory ||= File.join(project_path, ".specjour")
    end

    def config_file
      @config_file ||= File.join(config_directory, CONFIG_FILE_NAME)
    end

    def pid
      if File.exists?(pid_file)
        File.read(pid_file).strip.to_i
      end
    end

    def pid_file
      File.join(config_directory, PID_FILE_NAME)
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

    def command
      ["rsync", "--daemon", "--config=#{config_file}", "--port=#{port}"]
    end

    def check_config_version
      File.read(config_file) =~ /\A# (\d.\d.\d[.rc\d]*)/
      if out_of_date? Regexp.last_match(1)
        $stderr.puts <<-WARN

Specjour has made changes to the way #{CONFIG_FILE_NAME} is generated.
Back up '#{config_file}',
remove it, and re-run the dispatcher to generate the new config file.

        WARN
      end
    end

    def out_of_date?(version)
      CONFIG_VERSION != version
    end

    def write_config
      if File.exists? config_file
        check_config_version
      else
        FileUtils.mkdir_p config_directory
        File.open(config_file, 'w') do |f|
          f.write config
        end
      end
    end

    def config
      <<-CONFIG
# #{CONFIG_VERSION}
# Rsync daemon config for #{project_name}
#
# Serve this project with the following command:
# $ #{(command | ['--no-detach']).join(' ')}
#
# Rsync with the following command:
# $ rsync -a --port=#{port} #{hostname}::#{project_name} /tmp/#{project_name}
#
use chroot = no
timeout = 20
read only = yes
pid file = ./.specjour/#{PID_FILE_NAME}

[#{project_name}]
  path = .
  exclude = .git* .specjour/rsync* doc tmp/* log
      CONFIG
    end
  end
end
