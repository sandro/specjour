module Specjour
  class Manager
    require 'dnssd'
    include DRbUndumped

    attr_accessor :project_name, :specs_to_run, :host, :dispatcher_uri, :worker_size

    def initialize
      @worker_size = 2
    end

    def project_path=(name)
      @project_path = name
    end

    def project_path
      @project_path ||= File.join("/tmp", project_name)
    end

    def dispatch
      @bjs.stop
      DRb.stop_service
      puts "Running #{specs_to_run.flatten.size} spec files..."
      rubylib = File.expand_path(File.join(File.dirname(__FILE__), "/.."))
      bin = File.expand_path(File.join(File.dirname(__FILE__), "/../../bin/worker.rb"))
      pids = []
      (1..worker_size).each do |index|
        pids << fork do
          exec("RUBYLIB='#{rubylib}' #{bin} #{project_path} #{dispatcher_uri} #{index} #{specs_to_run[index - 1].join(' ')}")
        end
      end
      pids.each {|p| Process.detach p}
      puts "Dispatched to workers."
    end

    def start
      drb_start
      announce_service
      Signal.trap('INT') { puts; puts "Shutting down worker..."; exit }
      DRb.thread.join
    end

    def drb_start
      DRb.start_service nil, self
      Kernel.puts "Server started at #{drb_uri}"
      at_exit { Kernel.puts 'shutting down DRb client'; DRb.stop_service }
    end

    def sync
      cmd "rsync -a --port=8989 #{host}::#{project_name} #{project_path}"
    end

    protected

    def cmd(command)
      Kernel.puts command
      system command
    end

    def drb_uri
      @drb_uri ||= URI.parse(DRb.uri)
    end

    def announce_service
      @bjs = DNSSD.register! "specjour_worker_#{object_id}", "_#{drb_uri.scheme}._tcp", nil, drb_uri.port
    end
  end
end
