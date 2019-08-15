World(Rack::Test::Methods)

When(/^I am signing up for the newsletter$/) do
  user = FactoryBot.build(:user)
  visit new_newsletter_subscription_path
  fill_in "user_personal_name", :with => user.personal_name
  fill_in "user_family_name", :with => user.family_name
  fill_in "user_email", :with => user.email
  check 'user_terms_of_service'
end

Then(/^my newsletter sign-up should be successful$/) do
  c = User.where("newsletter = 'Non-member'").count
  click_button "Subscribe", match: :first
  expect(page).to have_content("Thank you for subscribing")
  expect(User.where("newsletter = 'Non-member'").count).to eq(c+1)
end

Then(/^my newsletter sign-up should be rejected$/) do
  c = User.where("newsletter = 'Non-member'").count
  click_button "Subscribe", match: :first
  expect(page).to have_no_content("Thank you for subscribing")
  expect(page).to have_css("div#error_explanation")
  expect(User.where("newsletter = 'Non-member'").count).to eq(c)
end