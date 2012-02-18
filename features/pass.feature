Feature: Passing sample

  Background:
    Given anything

  Scenario: Winning
    When I do something good
    Then I should be successful

  Scenario: Losing
    When I do something bad
    Then I should not be successful

  Scenario Outline: Passing wins
    When I do something good with <thing>
    Then I should be successful

  Examples:
    | thing |
    | money |
    | time  |

  Scenario Outline: Passing flops
    When I do something bad with <thing>
    Then I should not be successful

  Examples:
    | thing |
    | money |
    | time  |

