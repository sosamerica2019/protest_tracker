def sign_in(email, password)
  visit '/users/sign_in'
  fill_in "user_email", :with => email
  fill_in "user_password", :with => password
  click_button "sign_in"
	@current_user = User.find_by_email(email)
end

def sign_out
  visit '/pages/welcome'
	click_link "sign_out_link"
	@current_user = nil
end

################################################

Given (/^there are several ([A-z ]+)$/) do |models|
  FactoryBot.create_list(models.singularize.gsub(" ", "_").to_sym, 4)
end

Given (/^there is an? ([^v][A-z ]{0,10})$/) do |model|
  @obj = FactoryBot.create(model.gsub(" ", "_").to_sym)
end

When (/^I am not logged in$/) do
  sign_out if @current_user
end

When (/^I am logged in$/) do
  sign_out if @current_user
  user = FactoryBot.create(:user)
  sign_in(user.email, "password")

  #save_and_open_page
end

When (/^there is some basic stuff$/) do
  FactoryBot.create(:completed_vote)
	FactoryBot.create(:completed_election)
	FactoryBot.create_list(:vc_member, 2)
end

When (/^I am an admin$/) do
  sign_out if @current_user
  user = FactoryBot.create(:admin)
  sign_in(user.email, "password")
end

When (/^I am one of the VC members$/) do
  sign_out if @current_user
  user = User.vc_members.first
  sign_in(user.email, "password")
end

When (/^I am logged in as an unverified user$/) do
  user = FactoryBot.create(:unverified_user)
  sign_in(user.email, "password")
end

When(/^I am logged in as an admin$/) do
  user = FactoryBot.create(:admin)
  sign_in(user.email, "password")
end

When(/^I am on the "(.*?)" page$/) do |page_name|
  page_name = page_name.downcase.gsub(' ', '_') + '_path'
  visit eval(page_name)
end

When(/^I am looking at a ([A-z ]+)$/) do |model_name|
  model = model_name.split.map { |w| w.capitalize }.join('').constantize
  record = model.first
  page_name = model_name + '_path(' + record.id.to_s + ')'
  visit eval(page_name)
end

When(/^I click on "(.+)"$/) do |text|
  find(:link_or_button, text: text, match: :first).click
end

When(/^I choose "(.*)"$/) do |radio|
  choose radio
end

When (/^I do not check "(.*)"$/) do |checkbox|
  uncheck checkbox
end

When(/^I do not fill in ([\w ]+)$/) do |field|
  field.gsub!(" ", "_")
  field.sub!("my_", "user_")
  fill_in field, :with => ""
end

When(/^I fill in "(.*)" as ([\w ]+)$/) do |input, field|
  field.gsub!(" ", "_")
  field.sub!("my_", "user_")
  fill_in field, :with => input
  @registering_email = input if field == "user_email"
end

Then(/^I should see "(.*?)"$/) do |text|
  if text.include?("election") and not text.downcase.include?("you ")  
	  # match 'running election' etc., avoid successful vote message
		e = Election.find_by_title(text)  # ensure election exists
		expect(e.nil?).to eq(false)
		expect(e.shown_publicly?).to eq(true)
		expect(page).to have_content(text)
  else
	  expect(page).to have_content(text)
	end
end

Then(/^I should not see "(.*?)"$/) do |text|
  expect(page).to have_no_content(text)
end

Then(/^I should see a (.+) field/) do |id|
  expect(page).to have_css("#" + id)
end

Then(/^I should not see a (.+) field/) do |id|
  expect(page).to have_no_css("#" + id)
end

Then(/^I should not see an error$/) do
  expect(page).to have_no_css(".internal-alert")
  expect(page).to have_no_content("error")
  expect(page).to have_no_content("session dump")
  expect(page).to have_no_content("full trace")
end

Then(/^I should not see a real error$/) do
  expect(page).to have_no_content("error")
  expect(page).to have_no_content("session dump")
  expect(page).to have_no_content("full trace")
end

Then(/^I should be redirected to (.+)$/) do |redir_target|
  # This also include I should be redirected to the "(.+)" page as a subcase
	
  if redir_target == "the homepage"
		m = page.current_url.match(/^http:\/\/[^\/]+\/(.*)/)
		curr = m[1]
		curr.sub!('?locale=en', '')
		expect(curr).to eq("") 
	elsif redir_target == "the election info page"
	  redir_target = new_candidacy_url(election_id: @election.id)
	elsif redir_target == "the candidates page"
	  redir_target = candidates_election_url(id: @election.id)
	elsif redir_target == "the voting page"
	  redir_target = voting_election_url(id: @election.id) 
	elsif m = redir_target.match(/the "(.+)" page/)
	  # prepare
		page_name = m[1].downcase.gsub(' ', '_') + '_url'
		redir_target = eval(page_name)
		#redir_target = "http://www.example.com/en" + eval(page_name)
	end
	
	if redir_target != "the homepage" # already dealt with
    redir_target.sub!("localhost:3000", "www.example.com")
    # remove localisation artefacts and params
    redir_target.sub!('?locale=en', '')
    redir_target.sub!('/en/', '/')
	  curr = page.current_url
    curr.sub!('?locale=en', '')
	  curr.sub!('/en/', '/')
		curr.sub!(/\?user\[.+$/, '')
    expect(curr).to eq(redir_target)
	end
end

But(/^now$/) do
 # just for language
end