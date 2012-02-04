Given /^a JSON data string with a currently playing song$/ do
  json_file = File.join("data", "getrecenttracks-playing.json")
  @json = File.read(json_file).strip
end

Given /^a JSON data string with no currently playing songs$/ do
  json_file = File.join("data", "getrecenttracks-quiet.json")
  @json = File.read(json_file).strip
end

When /^I parse the JSON$/ do
  @now_playing = NowPlaying.alloc.initWithJson(@json)
  @now_playing.json.should == @json
  @now_playing.json.to_s.should match(/Spock's Beard/), "JSON sanity check"
end

Then /^I should find the "([^"]*)"$/ do |property_name|
  @now_playing.send(property_name).should_not be_nil, "#{property_name} should not be nil"
end

When /^the now-playing flag should be "([^"]*)"$/ do |is_playing|
  expected = (is_playing == "on") ? be_true : be_false
  @now_playing.isPlaying.should expected, "#{property_name} should be #{is_playing}"
end
