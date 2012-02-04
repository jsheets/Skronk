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
  pending
end

Then /^I should find the JSON property "([^"]*)" with the values:$/ do |property_name, table|
  # table is a | perPage    | 2          |pending
end

Then /^the JSON property "([^"]*)" should have (\d+) entries$/ do |property_name, array_size|
  pending
end

When /^track (\d+) should have JSON properties:$/ do |track_index, table|
  # table is a | artist           | Spock's Beard         |pending
end
