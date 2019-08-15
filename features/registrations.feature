Feature: Registrations

  Background:
    Given I am not logged in

	@javascript
  Scenario: User signs up with valid minimum data
    When I am signing up
    And my data is valid
    Then my sign-up should be successful with a confirmation
		And I should be able to pay a membership fee
      
  Scenario: User signs up without email
    When I am signing up
    And I do not fill in my email
    Then my sign-up should be rejected

  Scenario: User signs up without password
    When I am signing up
    And I do not fill in my password
    Then my sign-up should be rejected

  Scenario: User signs up without password confirmation
    When I am signing up
    And I do not fill in my password confirmation
    Then my sign-up should be rejected
	
	Scenario: User signs up without confirming
    When I am signing up
    And I do not accept the terms
    Then my sign-up should be rejected

  Scenario: User signs up with cellphone number
    When I am signing up
    And I fill in "+49 123 456789" as my mobile
    Then my sign-up should be successful with a confirmation
		
	Scenario: User tries to sign up but already has an account
	  When I am signing up
		And I fill in "test@test.com" as my email
		Then my sign-up should be successful with a confirmation
		But now
		Given I am not logged in
		When I am signing up
		And I fill in "test@test.com" as my email
		Then I should be asked to recover my password instead
		
	Scenario: User tries to sign up and already has a newsletter subscription
	  When I am signing up for the newsletter
		And I fill in "test2@test.com" as my email
		Then my newsletter sign-up should be successful
		But now
		When I am signing up
		And I fill in "test2@test.com" as my email
		Then my subscription for "test2@test.com" should be converted to membership