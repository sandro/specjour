require 'spec_helper'

describe Specjour::Loader do
  describe "#spec_files" do
    before do
      stub(Dir).pwd { '/home/someone/myproject' }
      stub(Dir).chdir
    end

    it "finds all specs in spec/ by default" do
      mock(Dir).[]("/myproject/spec/**/*_spec.rb") { ["/myproject/spec/foo_spec.rb"] }

      loader = described_class.new :project_path => "/myproject", :test_paths => ["/myproject"]
      loader.spec_files.should =~ ["/myproject/spec/foo_spec.rb"]
    end

    it "finds all specs in spec directory" do
      mock(File).expand_path("spec", "/myproject") { "/myproject/spec" }
      stub(File).directory?("/myproject/spec") { true }
      mock(Dir).[]("/myproject/spec/**/*_spec.rb") { ["/myproject/spec/foo_spec.rb"] }

      loader = described_class.new :project_path => "/myproject", :test_paths => ["spec"]
      loader.spec_files.should =~ ["/myproject/spec/foo_spec.rb"]
    end

    it "doesn't include feature files" do
      mock(File).expand_path(anything, "/myproject") { |p| "/myproject/#{p}" }
      stub(File).directory?("/myproject/spec") { true }
      mock(Dir).[]("/myproject/spec/**/*_spec.rb") { ["/myproject/spec/foo_spec.rb"] }

      loader = described_class.new :project_path => "/myproject", :test_paths => ["spec", "features/sign_up.feature"]
      loader.spec_files.should =~ ["/myproject/spec/foo_spec.rb"]
    end

    it "finds one spec file in addition to a directory of specs" do
      mock(File).expand_path(anything, "/myproject") { |p| "/myproject/#{p}" }.times(2)
      stub(File).directory? { |d| d =~ /helpers/ }
      mock(Dir).[]("/myproject/spec/helpers/**/*_spec.rb") do
        [
          "/myproject/spec/helpers/application_helper_spec.rb",
          "/myproject/spec/helpers/phone_number_helper_spec.rb"
        ]
      end

      loader = described_class.new :project_path => "/myproject", :test_paths => ["spec/models/user_spec.rb", "spec/helpers"]
      loader.spec_files.should =~ [
        "/myproject/spec/models/user_spec.rb",
        "/myproject/spec/helpers/application_helper_spec.rb",
        "/myproject/spec/helpers/phone_number_helper_spec.rb"
      ]
    end

    it "finds a unique set of specs" do
      mock(File).expand_path(anything, "/myproject") { |p| "/myproject/#{p}" }.times(2)
      stub(File).directory? { |d| d =~ /helpers$/ }
      mock(Dir).[]("/myproject/spec/helpers/**/*_spec.rb") do
        [
          "/myproject/spec/helpers/application_helper_spec.rb",
          "/myproject/spec/helpers/phone_number_helper_spec.rb"
        ]
      end

      loader = described_class.new :project_path => "/myproject", :test_paths => ["spec/helpers/phone_number_helper_spec.rb", "spec/helpers"]
      loader.spec_files.should =~ [
        "/myproject/spec/helpers/application_helper_spec.rb",
        "/myproject/spec/helpers/phone_number_helper_spec.rb"
      ]
    end
  end
end
