Feature: Work creation
  Scenario: A user attempts to create a work
    Given the user is logged in
    And There are ojects in the system
    And the user goes to the new_work page
    And the user fills out the work form
    Then the work should be saved successfully
