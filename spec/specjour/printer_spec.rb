require 'spec_helper'

describe Specjour::Printer do
  include FakeFS::SpecHelpers::All

  def makefs(paths)
    FakeFS do
      paths.each do |k,v|
        FileUtils.mkdir_p k
        Dir.chdir k do
          v.each do |file|
            file = File.expand_path(file, Dir.pwd)
            if String === file
              FileUtils.mkdir_p File.dirname(file)
              FileUtils.touch file
            elsif Hash === file
              makefs(file)
            end
          end
        end
      end
    end
  end

  before do
    makefs(
      '/home/someone/project1' => [
        'Rakefile',
        'spec/models/article_spec.rb',
        'spec/models/category_spec.rb'
      ],
      '/home/someone/project2' => [
        'Rakefile',
        'spec/models/user_spec.rb',
        'spec/models/profile_spec.rb'
      ]
    )
  end

# specjour (Dir.pwd)
# specjour spec/foo
# specjour spec/foo spec/bar
# specjour ~/baz
# specjour ~/baz/meh ~/baz/meh/moo
# specjour ../foo

  describe "set_paths" do
    before do
      Dir.chdir("/home/someone/project1")
    end

    it "handles no paths" do
      printer = Specjour::Printer.new test_paths: []
      expect(printer.project_name).to eq("project1")
      expect(printer.test_paths).to eq([])
      expect(printer.project_path).to eq("/home/someone/project1")
    end

    it "handles a project relative path" do
      printer = Specjour::Printer.new test_paths: ["spec/models/"]
      expect(printer.project_name).to eq("project1")
      expect(printer.test_paths).to eq(["spec/models"])
      expect(printer.project_path).to eq("/home/someone/project1")
    end

    it "handles two project relative paths" do

    end

    it "handles a project relative path and file" do

    end

    it "handles a relative path" do

    end

    it "handles two relative paths" do

    end

    it "handles an absolute path" do

    end

    it "handles two absolute paths" do

    end
  end

  # describe "#tests=" do
  #   before do
  #     stub(File).exists? { false }
  #   end
  #   it "sets the example size to the tests size" do
  #     subject.send(:tests=, nil, [1,2])
  #     subject.example_size.should == 2
  #   end

  #   it "accumulates features" do
  #     subject.send(:tests=, nil, ["one.feature", "two.feature"])
  #     subject.tests_to_run.should =~ ["one.feature", "two.feature"]
  #   end

  #   it "accumlates specs" do
  #     subject.send(:tests=, nil, ["one_spec.rb", "two_spec.rb"])
  #     subject.tests_to_run.should =~ ["one_spec.rb", "two_spec.rb"]
  #   end

  #   it "disregards duplicates" do
  #     subject.send(:tests=, nil, ["one_spec.rb", "two_spec.rb"])
  #     subject.send(:tests=, nil, ["one_spec.rb", "two_spec.rb"])
  #     subject.tests_to_run.should =~ ["one_spec.rb", "two_spec.rb"]
  #   end

  #   it "doesn't increment example_size with duplicates" do
  #     subject.send(:tests=, nil, ["one_spec.rb", "two_spec.rb"])
  #     subject.send(:tests=, nil, ["one_spec.rb", "two_spec.rb"])
  #     subject.example_size.should == 2
  #   end
  # end

  # describe "#exit_status" do
  #   let(:rspec_report) { Object.new }
  #   let(:cucumber_report) { Object.new }

  #   context "when cucumber_report is nil" do
  #     context "and rspec_report has true exit status" do
  #       before do
  #         stub(rspec_report).exit_status { true }
  #         subject.instance_variable_set(:@rspec_report, rspec_report)
  #       end

  #       it "has a true exit status" do
  #         subject.exit_status.should be_true
  #       end
  #     end

  #     context "and rspec_report has false exit status" do
  #       before do
  #         stub(rspec_report).exit_status { false }
  #         subject.instance_variable_set(:@rspec_report, rspec_report)
  #       end

  #       it "has a true exit status" do
  #         subject.exit_status.should be_false
  #       end
  #     end
  #   end

  #   context "when rspec report is nil" do
  #     context "and cucumber_report has true exit status" do
  #       before do
  #         stub(cucumber_report).exit_status { true }
  #         subject.instance_variable_set(:@cucumber_report, cucumber_report)
  #       end

  #       it "has a true exit status" do
  #         subject.exit_status.should be_true
  #       end
  #     end

  #     context "and cucumber_report has false exit status" do
  #       before do
  #         stub(cucumber_report).exit_status { false }
  #         subject.instance_variable_set(:@cucumber_report, cucumber_report)
  #       end

  #       it "has a true exit status" do
  #         subject.exit_status.should be_false
  #       end
  #     end
  #   end

  #   context "when both rspec and cucumber reports exists" do
  #     context "and rspec exit status is false" do
  #       before do
  #         stub(rspec_report).exit_status { false }
  #         stub(cucumber_report).exit_status { true }
  #         subject.instance_variable_set(:@cucumber_report, cucumber_report)
  #         subject.instance_variable_set(:@rspec_report, rspec_report)
  #       end

  #       it "returns false" do
  #         subject.exit_status.should be_false
  #       end
  #     end

  #     context "and cucumber exit status is false" do
  #       before do
  #         stub(rspec_report).exit_status { true }
  #         stub(cucumber_report).exit_status { false }
  #         subject.instance_variable_set(:@cucumber_report, cucumber_report)
  #         subject.instance_variable_set(:@rspec_report, rspec_report)
  #       end

  #       it "returns false" do
  #         subject.exit_status.should be_false
  #       end
  #     end

  #     context "both cucumber and rspec exit status are true" do
  #       before do
  #         stub(rspec_report).exit_status { true }
  #         stub(cucumber_report).exit_status { true }
  #         subject.instance_variable_set(:@cucumber_report, cucumber_report)
  #         subject.instance_variable_set(:@rspec_report, rspec_report)
  #       end

  #       it "returns false" do
  #         subject.exit_status.should be_true
  #       end
  #     end
  #   end
  # end
end
