module Specjour
  module CPU
    def self.cores
      case RUBY_PLATFORM
      when /darwin/
        command('hostinfo') =~ /^(\d+).+logically/
        $1.to_i
      when /linux/
        command('grep --count processor /proc/cpuinfo').to_i
      end
    end

    protected

    def self.command(cmd)
      %x(#{cmd})
    end
  end
end
