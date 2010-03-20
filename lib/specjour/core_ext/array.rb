module Specjour
  module Among
    def among(group_size)
      group_size = 1 if group_size.zero?
      groups = Array.new(group_size) { [] }
      offset = 0
      each do |item|
        groups[offset] << item
        offset = (offset == group_size - 1) ? 0 : offset + 1
      end
      groups
    end
  end
end
::Array.send(:include, Specjour::Among)
