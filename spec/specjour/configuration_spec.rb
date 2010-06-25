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
          mock(ActiveRecord::Base).connection { mock!.disconnect! }
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

  describe "#preload_app?" do
    it "defaults to true" do
      subject.preload_app?.should be_true
    end

    it "returns false when not preloading app" do
      subject.preload_app = false
      subject.preload_app?.should be_false
    end
  end
end
