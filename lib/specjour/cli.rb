module Specjour
  require 'thor'
  class CLI < Thor
    default_task :dispatch

    desc "manage", "Advertise availability to run specs"
    method_option :workers, :type => :numeric, :desc => "Number of concurent processes to run"
    method_option :projects, :type => :array, :desc => "Projects supported by this manager"
    def manage(number=1)
      p number
      p options
    end

    desc "dispatch [PROJECT_PATH]", "Run specs in this project"
    method_option :workers, :type => :numeric, :desc => "Number of concurent processes to run"
    method_option :alias, :desc => "Project name advertised to listeners"
    def dispatch(path = Dir.pwd)
      p path
      p options
    end

    desc "version", "Show the version of specjour"
    def version
      puts Specjour::VERSION
    end

    desc "work", "INTERNAL USE ONLY"
    def work
      puts 'working'
    end

    def self.printable_tasks
      super.reject{|t| t.last =~ /INTERNAL USE/ }
    end
  end
end
