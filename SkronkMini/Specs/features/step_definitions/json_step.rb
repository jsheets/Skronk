Given /^a JSON data string with a currently playing song$/ do
  json_file = File.join("data", "getrecenttracks-playing.json")
  @json = File.read(json_file).strip
end

Given /^a JSON data string with no currently playing songs$/ do
  json_file = File.join("data", "getrecenttracks-quiet.json")
  @json = File.read(json_file).strip
end

When /^I parse the JSON$/ do
  @fm_json = FMJson.alloc.initWithJson(@json)
end

Then /^I should find the JSON property "([^"]*)"$/ do |property_name|
  @fm_json.valueForProperty(property_name).should_not be_nil
end

Then /^I should find the JSON property "([^"]*)" with the values:$/ do |property_name, table|
  value = @fm_json.valueForProperty(property_name)
  value.should_not be_nil, "Property #{property_name} should exist"
  validate_table(table, value)
end

Then /^the JSON property "([^"]*)" should have (\d+) entries$/ do |property_name, array_size|
  @array = @fm_json.valueForProperty(property_name)
  @array.should_not be_nil, "Property #{property_name} should exist"
  @array.count.should == array_size
end

When /^track (\d+) should have JSON properties:$/ do |track_index, table|
  track = @array[track_index]
  track.should_not be_nil, "Track #{track_index} should exist"
  validate_table(table, track)
end
