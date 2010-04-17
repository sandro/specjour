module Specjour
  module CPU
    # copied from github.com/grosser/parallel
    def self.cores
      case RUBY_PLATFORM
      when /darwin/
        `hwprefs cpu_count`.to_i
      when /linux/
        `cat /proc/cpuinfo | grep --count processor`.to_i
      end
    end
  end
end
