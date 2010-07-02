require 'spec_helper'

describe Specjour::Configuration do
  subject do
    Specjour::Configuration
  end

  before { subject.reset }

  describe "#before_fork" do
    context "default proc" do
      context "ActiveRecord defined" do
        before do
          Object.const_set(:ActiveRecord, Module.new)
          ActiveRecord.const_set(:Base, Class.new)
        end

        after do
          Object.send(:remove_const, :ActiveRecord)
        end

        it "disconnects from the database" do
          mock(ActiveRecord::Base).remove_connection
          subject.before_fork.call
        end
      end

      context "ActiveRecord not defined" do
        it "does nothing" do
          subject.before_fork.call.should be_nil
        end
      end
    end

    context "custom proc" do
      it "runs block" do
        subject.before_fork = lambda { :custom_before }
        subject.before_fork.call.should == :custom_before
      end
    end
  end

  describe "#after_fork" do
    it "defaults to nothing" do
      subject.after_fork.call.should be_nil
    end

    it "runs the block" do
      subject.after_fork = lambda { :custom_after }
      subject.after_fork.call.should == :custom_after
    end
  end

  describe "#prepare" do
    it "defaults to nothing" do
      subject.prepare.call.should be_nil
    end

    it "runs the block" do
      subject.prepare = lambda { :custom_preparation }
      subject.prepare.call.should == :custom_preparation
    end
  end
end
