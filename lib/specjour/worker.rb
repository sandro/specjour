module Specjour
  class Worker
    include DRbUndumped

    attr_accessor :project_name, :specs_to_run, :host, :number
    attr_reader :project_path

    def initialize(project_path = nil)
      @project_path = project_path
    end

    def hash
      @hash ||= Time.now.to_f.to_s.sub(/\./,'')
    end
    alias object_id hash

    def project_path=(name)
      @project_path ||= name
    end

    def run
      puts "Running command #{spec_command.inspect}"
      Open3.popen3(spec_command) do |stdin, stdout, stderr|
        stdout.read
      end
    end

    def start
      DRb.start_service nil, self
      puts "DRB server running at #{drb_uri}"
      announce_service
      trap("INT") { DRb.stop_service }
      DRb.thread.join
    end

    def sync
      p "syncing"
      self.project_path = File.join("/tmp", project_name)
      cmd "rsync -a --port=8989 #{host}::#{project_name} #{project_path}"
    end

    protected

    def cmd(command)
      puts command
      system command
    end

    def drb_uri
      URI.parse(DRb.uri)
    end

    def spec_command
      test_env_number = (number == 1 ? nil : "TEST_ENV_NUMBER=#{number}") # parallel_spec compat
      "cd #{project_path} && #{test_env_number} spec #{specs_to_run.join(" ")}"
    end

    def announce_service
      puts "registering specjour_worker_#{object_id}"
      DNSSD.register "specjour_worker_#{object_id}", "_#{drb_uri.scheme}._tcp", nil, drb_uri.port
    end
  end
end
