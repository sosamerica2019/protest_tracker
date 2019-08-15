Feature: Newsletter

  Background:
    Given I am not logged in

  Scenario: User signs up with valid minimum data
    When I am signing up for the newsletter
    And my data is valid
    Then my newsletter sign-up should be successful
		
	Scenario: User signs up without confirming
    When I am signing up for the newsletter
    And I do not check "user_terms_of_service"
    Then my newsletter sign-up should be rejected
      
  Scenario: User signs up without email
    When I am signing up for the newsletter
    And I do not fill in my email
    Then my newsletter sign-up should be rejected

  Scenario: User signs up without personal name
    When I am signing up for the newsletter
    And I do not fill in my personal name
    Then my newsletter sign-up should be rejected