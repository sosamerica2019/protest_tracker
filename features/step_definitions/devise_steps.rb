# encoding: UTF-8

World(Rack::Test::Methods)

When(/^I am signing up$/) do
  user = FactoryBot.build(:user)
  visit new_user_registration_path
  fill_in "user_personal_name", :with => user.personal_name
  fill_in "user_family_name", :with => user.family_name
  fill_in "user_email", :with => user.email
  fill_in "user_password", :with => user.password
  fill_in "user_password_confirmation", :with => user.password
	check "user_terms_of_service"
	@registering_email = user.email
end

When(/^I am signing up for MeRA25$/) do
  user = FactoryBot.build(:user)
  visit new_user_registration_path('org' => 'mera25')
  fill_in "user_personal_name", :with => user.personal_name
  fill_in "user_family_name", :with => user.family_name
  fill_in "user_email", :with => user.email
  fill_in "user_password", :with => user.password
  fill_in "user_password_confirmation", :with => user.password
	fill_in "user_full_legal_name", :with => user.name
	fill_in "user_birthdate", :with => Date.parse("1984-01-01")
	fill_in "user_mobile", :with => "+3311112222"
	fill_in "user_postal_code", :with => "33333"
	fill_in "user_voting_district", :with => "Athens B"
	check "user_terms_of_service"
	@registering_email = user.email
end

When(/^I do not accept the terms$/) do
  expect(page).to have_css("#user_terms_of_service") 
	find(:css, "#user_terms_of_service").set(false)
end

When(/^I am editing my profile$/) do
  visit "/users/edit"
  fill_in "user_current_password", :with => "password"
end

When(/^my data is valid$/) do
  # this is the default
end

When(/^my account is young$/) do
  @current_user.update_attribute(:created_at, Time.now)
end

When(/^my (\w+) is "(.*)"/) do |field, value|
  @current_user.update_attribute(field, value)
end

When(/^I request a password as a regular user$/) do
  user = FactoryBot.create(:user)
  visit "/users/password/new"
	fill_in "user_email", :with => user.email
	click_button "Send me instructions"
end

When(/^I request a password as a non-user$/) do
  visit "/users/password/new"
	fill_in "user_email", :with => "uhiuhhiuhujh@gmail.com"
	click_button "Send me instructions"
end

When(/^I request a password as a newsletter subscriber$/) do
  user = FactoryBot.create(:newsletter_subscriber)
  visit "/users/password/new"
	fill_in "user_email", :with => user.email
	click_button "Send me instructions"
end

Then(/^my sign-up should be successful$/) do
  Then("my sign-up should be successful with a confirmation")
end

Then(/^my sign-up should be successful (with|without) a confirmation$/) do |confirmation|
  c = User.where("newsletter = 'Member'").count
  click_button I18n.t("register.button2"), match: :first
	if confirmation == "with"
	  expect(User.last.verification_state).to eq(0)
    expect(User.last.confirmed?).to be false
	elsif confirmation == "without"
	  expect(User.last.verification_state).to eq(1)
    expect(User.last.confirmed?)
	end
	if User.last.locale == :en
	  expect(page).to have_css("h3", :text => "DiEM25 is ours.")  # membership fee page
	end
  expect(User.where("newsletter = 'Member'").count).to eq(c+1)
	@current_user = User.last
end

Then(/my sign-up should be half-way/) do 
  c = User.where("newsletter = 'Member'").count
  click_button "Εγγραφή", match: :first
  expect(User.where("newsletter = 'Member'").count).to eq(c+1)
  expect(User.last.confirmed?).to be false
	expect(User.last.verification_state).to eq(-1)
	@current_user = User.last
end

Then(/^my subscription for "(.*)" should be converted to membership$/) do |email|
  this_id = User.find_by_email(email).id
	@registering_email = email
	c = User.count
	fill_in "user_twitter", :with => "@someone"  # ensure other info is added as well
  click_button I18n.t("register.button2"), match: :first
	#expect(page).to have_content("message with a confirmation link has been sent")
  expect(User.count).to eq(c)
	u = User.find_by_email(email)
	expect(u.id).to eq(this_id)
	expect(u.newsletter).to eq("Member")
	expect(u.twitter).to eq("@someone")
	expect(u.valid_password?("password")).to eq(true)
	expect(u.verification_state).to eq(1)
	if User.last.locale == :en
	  expect(page).to have_css("h3", :text => "DiEM25 is ours.") 
	end
end

Then(/^my sign-up should be rejected$/) do
  c = User.where("newsletter = 'Member'").count
  click_button I18n.t("register.button2"), match: :first
  expect(page).to have_no_content("message with a confirmation link has been sent")
	expect(page).to have_no_css("h3", :text => "DiEM25 is ours.")
	expect(page).to have_css("div#error_explanation") 
  expect(User.where("newsletter = 'Member'").count).to eq(c)
end

Then(/^I should be asked to recover my password instead$/) do
  c = User.count
  click_button I18n.t("register.button2"), match: :first
  expect(page).to have_no_content("message with a confirmation link has been sent")
	expect(page).to have_no_css("h3", :text => "DiEM25 is ours.")
	expect(page).to have_css("div.alert", :text => "recover your password") 
  expect(User.count).to eq(c)
end

Then(/^I should be able to pay a membership fee$/) do
  choose "membership_fee_regular"
  choose "membership_paytype_bank"
	click_button "This is my choice!"
	expect(User.find_by_email(@registering_email).membership_fee).to eq("regular")
	expect(page).to have_content("5.00 (Monthly donation)")
end

Then(/^my edit should be successful$/) do
  click_button "Update"
  expect(page).to have_content("successfully")
end

Then(/^my edit should be rejected$/) do
  click_button "Update"
  expect(page).to have_no_content("successfully")
  expect(page).to have_css("div#error_explanation")
end

Then(/I should receive an email containing my data/) do
	email = ApplicationMailer.deliveries.last
  expect(email).not_to be_nil
  expect(email.subject).to eq("Your data")
	body = email.body.encoded
	expect(body).to match /male/  # User table
	expect(body).to match /have a reason really/ # Candidacy table

end