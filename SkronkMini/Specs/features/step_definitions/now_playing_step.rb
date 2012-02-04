When /^I parse the Now Playing JSON$/ do
  @now_playing = NowPlaying.alloc.initWithJson(@json)
  @now_playing.json.should == @json
  @now_playing.json.to_s.should match(/Spock's Beard/), "JSON sanity check"
end

#Then /^I should find the "([^"]*)"$/ do |property_name|
#  @now_playing.send(property_name).should_not be_nil, "#{property_name} should not be nil"
#end

When /^the now-playing flag should be "([^"]*)"$/ do |is_playing|
  expected = (is_playing == "on") ? 1 : 0
  @now_playing.isPlaying.should == expected#, "isPlaying should be #{is_playing}"
end
