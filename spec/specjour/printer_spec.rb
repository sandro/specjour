require 'spec_helper'

describe Specjour::Printer do
  subject do
    Specjour::Printer.new []
  end

  describe "#exit_status" do
    let(:rspec_report) { Object.new }
    let(:cucumber_report) { Object.new }

    context "when cucumber_report is nil" do
      context "and rspec_report has true exit status" do
        before do
          stub(rspec_report).exit_status { true }
          subject.instance_variable_set(:@rspec_report, rspec_report)
        end

        it "has a true exit status" do
          subject.exit_status.should be_true
        end
      end

      context "and rspec_report has false exit status" do
        before do
          stub(rspec_report).exit_status { false }
          subject.instance_variable_set(:@rspec_report, rspec_report)
        end

        it "has a true exit status" do
          subject.exit_status.should be_false
        end
      end
    end

    context "when rspec report is nil" do
      context "and cucumber_report has true exit status" do
        before do
          stub(cucumber_report).exit_status { true }
          subject.instance_variable_set(:@cucumber_report, cucumber_report)
        end

        it "has a true exit status" do
          subject.exit_status.should be_true
        end
      end

      context "and cucumber_report has false exit status" do
        before do
          stub(cucumber_report).exit_status { false }
          subject.instance_variable_set(:@cucumber_report, cucumber_report)
        end

        it "has a true exit status" do
          subject.exit_status.should be_false
        end
      end
    end

    context "when both rspec and cucumber reports exists" do
      context "and rspec exit status is false" do
        before do
          stub(rspec_report).exit_status { false }
          stub(cucumber_report).exit_status { true }
          subject.instance_variable_set(:@cucumber_report, cucumber_report)
          subject.instance_variable_set(:@rspec_report, rspec_report)
        end

        it "returns false" do
          subject.exit_status.should be_false
        end
      end

      context "and cucumber exit status is false" do
        before do
          stub(rspec_report).exit_status { true }
          stub(cucumber_report).exit_status { false }
          subject.instance_variable_set(:@cucumber_report, cucumber_report)
          subject.instance_variable_set(:@rspec_report, rspec_report)
        end

        it "returns false" do
          subject.exit_status.should be_false
        end
      end

      context "both cucumber and rspec exit status are true" do
        before do
          stub(rspec_report).exit_status { true }
          stub(cucumber_report).exit_status { true }
          subject.instance_variable_set(:@cucumber_report, cucumber_report)
          subject.instance_variable_set(:@rspec_report, rspec_report)
        end

        it "returns false" do
          subject.exit_status.should be_true
        end
      end
    end
  end
end
