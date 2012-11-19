module Specjour
  module Cucumber
    module Runner
      def self.run(feature)
        Cucumber.runtime.instance_eval do
          @loader = nil
          @configuration.parse!([feature])
          tree_walker = @configuration.build_tree_walker(self)
          self.visitor = tree_walker
          tree_walker.visit_features features
        end
      end
    end
  end
end
