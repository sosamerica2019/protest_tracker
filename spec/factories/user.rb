FactoryBot.define do
  male_names = ["Adam", "Bob", "Chris", "Dave", "Ed", "John", "Ken", "Mike"]
	female_names = ["Anna", "Bella", "Catherine", "Dolly", "Erin", "Julia", "Katrin", "Mia"] 

  factory :user, aliases: [:initiator]  do
    personal_name { male_names.sample }
    family_name { ["Avery", "Doe", "Muller", "Neumann", "Owen", "Richards", "Smith", "Thomson"].sample }
    gender { "male" }
    sequence(:email) { |n| "yutian.mei+mtest#{n}@gmail.com" }
    password { "password" }
    password_confirmation { "password" }
    created_at { (Time.now - 2.months) }
		current_sign_in_at { (Time.now - 1.day) }
    confirmed_at { (Time.now - 2.months) }
    confirmation_token { nil }
    admin_level { 0 }
    verification_state { 3 }
    language { "English" }
		newsletter { "Member" }
		
		before(:create) do |u|
      if u.gender == "female"
			  u.personal_name = female_names.sample
			elsif u.gender == "male"
			  u.personal_name = male_names.sample
			else
			  u.personal_name = (male_names + female_names).sample
			end
    end
		
		
		transient do
		  election_candidate_in { nil }
			election_post_id { nil }
			candidate_approved { true }
		end
    
    factory :admin do
      admin_level { 9 }
			family_name { "Doe (admin)" }
    end
    
    factory :unverified_user do
      verification_state { 1 }
    end
    
    factory :fresh_user do
      verification_state { 0 }
      confirmed_at { nil }
      created_at { Time.now }
    end
    
    factory :vc_candidate do
      gender { ["female", "male", "other", "prefer not to say"].sample }
			#if gender == "female"
			  #personal_name = female_names.sample
			#end
      vc_candidate_since { (Time.now - 2.months) }
      vc_member_since { nil }
    end
		
		factory :vc_member do
      gender { ["female", "male", "other"].sample }
			#if gender == "female"
			  #personal_name = female_names.sample
			#end
      vc_candidate_since { (Time.now - 2.months) }
      vc_member_since { (Time.now - 1.month) }
		end
		
		factory :election_candidate do
		  sequence(:personal_name) { |n| "Candidate #{n}" }
			sequence(:email) { |n| "yutian.mei+candidate#{n}@gmail.com" }
			gender { ["female", "male", "other"].sample }
			#if gender == "female"
			  #personal_name = female_names.sample
			#end
			created_at { (Time.now - 1.year) }
			after(:create) do |candidate, evaluator|
			  post = evaluator.election_post_id
				if post.nil? and evaluator.election_candidate_in.has_posts?
				  post = evaluator.election_candidate_in.election_posts.pluck(:id).sample  # random post if election has posts and otherwise unspecified
				end
			  FactoryBot.create(:candidacy, user_id: candidate.id, election: evaluator.election_candidate_in, 
				   gender: candidate.gender, approved: evaluator.candidate_approved, election_post_id: post)
      end
		end
		
		factory :newsletter_subscriber do
		  password { "56454agagaeg" }
			password_confirmation { "56454agagaeg" }
			newsletter { "Non-member" }
			verification_state { 1 }
		end
  end
end