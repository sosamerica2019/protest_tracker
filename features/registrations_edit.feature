Feature: Registrations edit

  Background:
    Given I am logged in

  Scenario: I edit my name
    When I am editing my profile
    And I fill in "Jane" as my personal name
    Then my edit should be successful
  
  Scenario: I edit my cellphone
    When I am editing my profile
    And I fill in "+49 123 456789" as my mobile
    Then my edit should be successful  
 
  Scenario: No editing without current password
    When I am editing my profile
    And I fill in "Jane" as my personal name
    And I do not fill in my current password
    Then my edit should be rejected 

  Scenario: Changing password via the profile
    When I am editing my profile
    And I fill in "lovelove" as my password
    And I fill in "lovelove" as my password confirmation
    Then my edit should be successful 
    
  Scenario: Changing password via the profile
    When I am editing my profile
    And I fill in "lovelove" as my password
    And I do not fill in my password confirmation
    Then my edit should be rejected
	
	@javascript
	Scenario: Exporting one's data
	  When there is an election I have applied to
		And I am editing my profile
		And I click on "Export my data"
		Then I should receive an email containing my data