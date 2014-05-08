module Specjour
  module CPU
    def self.cores
      case platform
      when /darwin/
        command('hostinfo') =~ /^(\d+).+physically/
        $1.to_i
      when /linux/
        command('grep --count processor /proc/cpuinfo').to_i
      end
    end

    def self.half_cores
      cores / 2
    end

    protected

    def self.command(cmd)
      %x(#{cmd})
    end

    def self.platform
      RUBY_PLATFORM
    end
  end
end
