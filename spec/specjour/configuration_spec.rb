require 'spec_helper'
require 'rspec/core/formatters/progress_formatter'

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

CustomFormatter ||= Class.new

describe Specjour::Configuration do

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

          context "and bundler options set" do
            before do
              subject.bundler_options = "--binstubs"
            end

            it "runs 'bundle install' with the given options" do
              mock(subject).system('bundle install --binstubs')
              subject.before_fork.call
            end
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

  describe "#bundler_options" do
    it "allows custom bundler_options to be set" do
      subject.bundler_options = '--binstubs=bin/stubs'
      subject.bundler_options.should == '--binstubs=bin/stubs'
    end

    it "defaults to no bundler options" do
      subject.bundler_options.should == ""
    end
  end

  describe "#rsync_options" do
    it "allows custom rsync_options to be set" do
      subject.rsync_options = '-a'
      subject.rsync_options.should == '-a'
    end

    it "defaults to archive, symbolic links, delete, and ignore errors" do
      subject.rsync_options.should == "-aL --delete --ignore-errors"
    end
  end

  describe "#rspec_formatter" do
    it "allows custom rsync_options to be set" do
      subject.rspec_formatter = lambda { CustomFormatter }
      subject.rspec_formatter.call.should == CustomFormatter
    end

    it "defaults to the progress formatter" do
      subject.rspec_formatter.call.should == ::RSpec::Core::Formatters::ProgressFormatter
    end
  end
end
