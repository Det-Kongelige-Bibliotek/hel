Feature: User log in
  Scenario: An administrator wants to login
    Given the user is on the login page
    And the user enters correct login details
    Then they should login successfully

  Scenario: A user without access attempts to login
    Given the user is on the login page
    And the user enters incorrect login details
    Then they should not be allowed to login