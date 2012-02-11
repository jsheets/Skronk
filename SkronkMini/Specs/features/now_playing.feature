# Cucumber Feature

Feature: NowPlaying last.fm parser
  In order to reliably parse last.fm now-playing data
  As an application developer
  I want a simple, minimal API

  Scenario: A track is currently playing
    Given a JSON data string with a currently playing song
    When I parse the Now Playing JSON
    Then the now-playing flag should be "on"
    And the "artist" should be "Playing Spock's Beard"
    And the "album" should be "Playing X"
    And the "track" should be "Playing The Emperor's Clothes"

  Scenario: No tracks are currently playing
    Given a JSON data string with no currently playing songs
    When I parse the Now Playing JSON
    Then the now-playing flag should be "off"
    And the "artist" should be "Spock's Beard"
    And the "album" should be "X"
    And the "track" should be "From The Darkness"