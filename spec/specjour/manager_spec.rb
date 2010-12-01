require 'spec_helper'

describe Specjour::Manager do
  describe "#available_for?" do
    subject { Specjour::Manager.new }
    it "isn't available for all projects by default" do
      subject.available_for?(rand.to_s).should be_false
    end

    it "is available for one project" do
      manager = Specjour::Manager.new :registered_projects => %w(one)
      manager.available_for?('one').should be_true
    end

    it "is available for many projects" do
      manager = Specjour::Manager.new :registered_projects => %w(one two)
      manager.available_for?('one').should be_true
      manager.available_for?('two').should be_true
    end
  end
end
