Feature: Import from Aleph
  In order to import records from Aleph
  As an administrator
  I want to be able to import work metadata from Aleph

  Scenario: A user wants to import an Aleph record using an ISBN
    Given the user is logged in
    And the user is on the new_work page
    When the user fills out the aleph import form with ISBN 9788711396322
    Then the work should be saved successfully