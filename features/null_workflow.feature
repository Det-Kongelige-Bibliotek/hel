Feature: Null Workflow
  In order to ingest material with incomplete metadata
  As a curator
  I want to be able to save mixed material into the system

  Scenario: Getting to the input form
    Given the user is logged in
    When the user clicks on the 'Nyt arkiv' link
    Then the page should return successfully

  Scenario: Filling out the form
    Given the user is logged in
    And the user is on the new_mixed_material page
    When the user fills out the mixed material form
    Then the mixed material should be saved successfully


  Scenario: Non-logged in user
    When the user is not logged in
    Then the content 'Nyt arkiv' should not be present