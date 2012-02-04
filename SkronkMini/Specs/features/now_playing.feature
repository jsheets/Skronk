# Cucumber Feature

Feature: NowPlaying last.fm parser
  In order to reliably parse last.fm now-playing data
  As an application developer
  I want a simple, minimal API

  Scenario: A track is currently playing
    Given a JSON data string with a currently playing song
    When I parse the JSON
    Then I should find the "artist"
    And I should find the "album"
    And I should find the "track"
    And the now-playing flag should be "on"

  Scenario: No tracks are currently playing
    Given a JSON data string with no currently playing songs
    When I parse the JSON
    Then I should find the "artist"
    And I should find the "album"
    And I should find the "track"
    And the now-playing flag should be "off"
