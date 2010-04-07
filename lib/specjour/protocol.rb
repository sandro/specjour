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
  end
end
