Feature: Devise stuff

  Background:
    Given I am not logged in

  Scenario: User wants to retrieve password
	  When I request a password as a regular user
		Then I should see "You will receive an email with instructions"
		
	Scenario: Non-user wants to retrieve password
	  When I request a password as a non-user
		Then I should see "There is no registered member with this email address."
	
	Scenario: Newsletter subscriber wants to retrieve password
	  When I request a password as a newsletter subscriber
		Then I should see "You are not registered as a member, only a newsletter subscriber"
		And I should be redirected to the "New user registration" page