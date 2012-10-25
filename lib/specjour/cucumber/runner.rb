module Specjour
  module Cucumber
    module Runner
      def self.run(feature_path)
        feature = ::Cucumber::FeatureFile.new(feature_path).parse(Cucumber.configuration.filters, {})

        features = ::Cucumber::Ast::Features.new

        features.add_feature(feature)




        Cucumber.tree_walker.visit_features(features)
      end
    end
  end
end
