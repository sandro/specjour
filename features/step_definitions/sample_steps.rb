Given /^anything$/ do
end

When /^I do something good$/ do
end

When /^I do something bad$/ do
end

When /^I do something that raises an exception$/ do
  raise StandardError
end

When /^I do something good with (.+)$/ do |thing|
end

When /^I do something bad with (.+)$/ do |thing|
end

Then /^I should not be successful$/ do
  false.should_not == true
end

Then /^I should be successful$/ do
  true.should == true
end

Then /^fail$/ do
  false.should == true
end

Then /^I will never pass$/ do
  true.should be_true
end
