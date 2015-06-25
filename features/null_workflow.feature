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
    And There are person objects in the system
    And there is a test activity in the system
    And the user is on the new_mixed_material page
    When the user fills out the mixed material form
    Then the material should be created

  Scenario: Editing a MixedMaterial object
    Given the user is logged in
    And the user has created a mixed material object
    When the user clicks on the 'Rediger' link
    Then the page should return successfully
    Then show me the page

  Scenario: Non-logged in user
    When the user is not logged in
    Then the content 'Nyt arkiv' should not be present