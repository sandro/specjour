module Specjour
  module Protocol
    TERMINATOR = "|ruojceps|"

    def puts(arg)
      print(arg << "\n")
    end

    def print(arg)
      super dump_object(arg)
    end

    def dump_object(data)
      Marshal.dump(data) << TERMINATOR
    end

    def load_object(data)
      Marshal.load(data.sub(/#{TERMINATOR}$/, ''))
    end
  end
end
