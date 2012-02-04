# Cucumber Feature

Feature: last.fm JSON Parser
  In order to parse last.fm JSON content
  As a developer
  I want a class to wrap it

# Run this for every scenario.

  Background:
    Given a JSON data string with a currently playing song
    When I parse the JSON

  Scenario: JSON top level
    Then I should find the JSON property "recenttracks"

  Scenario: JSON with attributes
    Then I should find the JSON property "recenttracks.@attr" with the values:
      | page       | 1          |
      | perPage    | 2          |
      | total      | 36598      |
      | totalPages | 18299      |
      | user       | johnsheets |

  Scenario: JSON array
    Then the JSON property "recenttracks.track" should have 3 entries
    And track 0 should have JSON properties:
      | @attr.nowplaying | true                  |
      | artist           | Spock's Beard         |
      | name             | The Emperor's Clothes |
      | streamable       | 0                     |
    And track 1 should have JSON properties:
      | album      | X                     |
      | artist     | Spock's Beard         |
      | date       | 4 Feb 2012, 01:17     |
      | name       | The Emperor's Clothes |
      | streamable | 0                     |
    And track 2 should have JSON properties:
      | album      | X                          |
      | artist     | Spock's Beard              |
      | date       | 4 Feb 2012, 01:10          |
      | name       | The Man Behind the Curtain |
      | streamable | 0                          |

