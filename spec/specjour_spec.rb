require 'spec_helper'

class CustomException < RuntimeError
end

def boo
  raise CustomException, 'fails'
end

describe Specjour do
  it "pends as an example"

  it "fails as an example" do
    boo
  end
end
