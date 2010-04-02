module Specjour
  module Protocol
    TERMINATOR = "|ruojceps|"
    TERMINATOR_REGEXP = /#{TERMINATOR}$/

    def dump_object(data)
      Marshal.dump(data) << TERMINATOR
    end

    def load_object(data)
      Marshal.load(data.sub(TERMINATOR_REGEXP, ''))
    end

    def print(arg)
      super dump_object(arg)
    end

    def puts(arg)
      print(arg << "\n")
    end

    def send_message(method_name, *args)
      print([method_name, *args])
      flush
    end
  end
end
