module Specjour
  class Worker
    include DRbUndumped

    attr_reader :project_path, :project_name, :specs_to_run

    def initialize(project_path, project_name)
      @project_path = project_path
      @project_name = project_name
    end

    def run(specs)
      self.specs_to_run = specs
      "Running command #{spec_command}"
      Open3.popen3(spec_command) do |stdin, stdout, stderr|
        stdout.read
      end
    end

    def sync
      "rsync -a --delete --port=8989 santurimob.local::#{project_name} /tmp/#{project_name}"
    end

    def start
      DRb.start_service nil, self
      puts "DRB server running at #{drb_uri}"
      announce_service
      trap("INT") { DRb.stop_service }
      DRb.thread.join
    end

    protected

    attr_writer :specs_to_run

    def drb_uri
      URI.parse(DRb.uri)
    end

    def spec_command
      "cd #{project_path} && spec #{specs_to_run}"
    end

    def announce_service
      DNSSD.register "specjour_worker_#{object_id}", "_#{drb_uri.scheme}._tcp", nil, drb_uri.port
    end
  end
end
