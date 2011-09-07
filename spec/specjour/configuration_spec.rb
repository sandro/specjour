require 'spec_helper'

module RailsAndActiveRecordDefined
  def self.extended(base)
    base.class_eval do
      before do
        rails = Module.new do
          def self.version
            "3.0.0"
          end
        end
        Object.const_set(:Rails, rails)
        Object.const_set(:ActiveRecord, Module.new)
        ActiveRecord.const_set(:Base, Class.new)
      end

      after do
        Object.send(:remove_const, :ActiveRecord)
        Object.send(:remove_const, :Rails)
      end
    end
  end
end

describe Specjour::Configuration do
  subject do
    Specjour::Configuration
  end

  before { subject.reset }

  describe "#before_fork" do
    context "default proc" do

      context "bundler installed" do
        before do
          mock(subject).system("which bundle") { true }
        end

        context "when gems not satisfied" do
          before do
            mock(subject).system("bundle check") { false }
          end

          it "runs 'bundle install'" do
            mock(subject).system('bundle install')
            subject.before_fork.call
          end
        end

        context "when gems are satisfied" do
          before do
            mock(subject).system("bundle check") { true }
          end

          it "doesn't run 'bundle install'" do
            dont_allow(subject).system('bundle install')
            subject.before_fork.call
          end
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

    context "ActiveRecord defined" do
      extend RailsAndActiveRecordDefined
      it "scrubs the db" do
        mock(Specjour::DbScrub).scrub
        subject.after_fork.call
      end
    end
  end

  describe "#after_load" do
    context "default proc" do
      context "ActiveRecord defined" do
        extend RailsAndActiveRecordDefined
        it "disconnects from the database" do
          mock(ActiveRecord::Base).remove_connection
          subject.after_load.call
        end
      end
    end

    context "custom proc" do
      it "runs block" do
        subject.after_load = lambda { :custom_before }
        subject.after_load.call.should == :custom_before
      end
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

    context "ActiveRecord defined" do
      extend RailsAndActiveRecordDefined
      it "drops then scrubs the db" do
        mock(Specjour::DbScrub).drop
        mock(Specjour::DbScrub).scrub
        subject.prepare.call
      end
    end
  end
end
