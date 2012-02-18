Feature: Undefined step definitions sample

  Background:
    Given anything

  Scenario:
    When I have this undefined step definition
    Then fail

  Scenario Outline:
    When I have this undefined step definition
    Then fail

  Examples:
    | thing |
    | money |
    | time  |
