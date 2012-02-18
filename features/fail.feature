Feature: Failing sample

  Background:
    Given anything

  Scenario: Winning
    When I do something good
    Then fail

  Scenario: Losing
    When I do something bad
    Then fail

  Scenario: Exceptions
    When I do something that raises an exception
    Then I will never pass

  Scenario Outline: Passing wins
    When I do something good with <thing>
    Then fail

  Examples:
    | thing |
    | money |
    | time  |

  Scenario Outline: Passing flops
    When I do something bad with <thing>
    Then fail

  Examples:
    | thing |
    | money |
    | time  |

