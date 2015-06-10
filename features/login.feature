Feature: User log in
  Scenario: An administrator wants to login
    Given the user is on the login page
    And the user enters correct login details
    Then they should login successfully

  Scenario: A user without access attempts to login
    Given the user is on the login page
    And the user enters incorrect login details
    Then they should not be allowed to login

  Scenario: A logged in user attempts to create a work
    Given the user is logged in
    And the user visits the new_work_path
    Then the page should return successfully

  Scenario: A non-logged in user attempts to create a work
    Given the user is not logged in
    And the user visits the new_work_path
    Then the user should be redirected to the root_path