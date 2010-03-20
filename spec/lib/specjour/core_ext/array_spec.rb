require 'spec_helper'

describe "Array splitting among many" do
  describe "#among" do
    let(:array) { [1,2,3,4,5] }

    it "splits among 0" do
      array.among(0).should == [[1,2,3,4,5]]
    end

    it "splits among by 1" do
      array.among(1).should == [[1,2,3,4,5]]
    end

    it "splits among by 2" do
      array.among(2).should == [[1,3,5],[2,4]]
    end

    it "splits among by 3" do
      array.among(3).should == [[1,4],[2,5],[3]]
    end

    it "splits among by 4" do
      array.among(4).should == [[1,5],[2],[3],[4]]
    end

    it "splits among by 5" do
      array.among(5).should == [[1],[2],[3],[4],[5]]
    end
  end
end
