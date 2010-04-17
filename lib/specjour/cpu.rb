module Specjour
  module CPU
    # inspired by github.com/grosser/parallel
    def self.cores
      case RUBY_PLATFORM
      when /darwin/
        `hwprefs cpu_count`.to_i
      when /linux/
        `grep --count processor /proc/cpuinfo`.to_i
      end
    end
  end
end
