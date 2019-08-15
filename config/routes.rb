Rails.application.routes.draw do
  
scope "(:locale)", locale: /en|de|fr|it|es|pt|el|nl|da|pl|ca|cs|sl/ do

  ActiveAdmin.routes(self)

  resources :dscs do
	  collection do
		  get 'view' => 'dscs#public_index', as: :public
			get 'export' => 'dscs#export', as: :export
		end
	end
	get 'ncs/new' => 'dscs#add_national', as: :new_nc
	post 'ncs/new' => 'dscs#create_update_national', as: :create_nc
	get 'ncs/:id' => 'dscs#edit_national', as: :edit_nc
	patch 'ncs/:id' => 'dscs#create_update_national', as: :update_nc
	
	resources :fundraisings
	
	resources :events do
	  collection do
		  get 'review' => 'events#reviewer_index', as: :review
		end
	end

  resources :petitions do
    member do
      post 'sign' => 'petitions#sign', as: :sign
    end
  end
  
  get 'referendum/new' => 'questions#new_votequestion', as: :new_referendum
  post 'referendum/create' => 'questions#create_votequestion', as: :create_referendum
  get 'referendum/:id' => 'questions#edit_votequestion', as: :edit_referendum
  get 'referendum/preview/:id' => 'questions#preview_votequestion', as: :preview_referendum
  post 'referendum/:id' => 'questions#update_votequestion', as: :update_referendum
	get 'vote/dashboard' => 'votes#dashboard', as: :vote_dashboard # old front page
  post 'vote/:id/give_tokens' => 'votes#give_tokens', as: :give_vote_tokens
  post 'vote/:id/close' => 'votes#close_vote', as: :close_vote
  get 'vote/:id/results' => 'votes#show_results', as: :vote_results
	get 'vote/:id/public' => 'votes#public_show', as: :public_show
  get 'vote/:id' => 'votes#show', as: :show_referendum
  post 'vote/:id' => 'votes#do_vote', as: :do_vote
  resources :questions
	
	resources :candidacies do
	  member do
		  get 'translate' => 'candidacies#translate', as: :translate
			post 'translate' => 'candidacies#store_translation', as: :store_translated
			get 'toggle_approve' => 'candidacies#toggle_approve', as: :toggle_approve
      post 'endorse' => 'candidacies#endorse', as: :endorse
      post 'unendorse' => 'candidacies#unendorse', as: :unendorse
		end
	end
  resources :elections do
	  member do
		  get 'candidates' => 'candidacies#index', as: :candidates
			get 'voting' => 'elections#voting', as: :voting
			post 'validate_vote' => 'elections#validate_vote', as: :validate_vote
      post 'voting' => 'elections#do_vote', as: :do_vote2
			post 'do_vote' => 'elections#do_vote', as: :do_vote
			post 'give_tokens' => 'elections#give_tokens', as: :give_tokens
			post 'close' => 'elections#close_vote', as: :close
			get 'results' => 'elections#results', as: :results
		end
	end
  
  get 'donations/thanks' => 'donations#thanks'
	get 'donations/to/:earmark' => 'donations#new_earmarked', as: :earmarked_donation
  post 'donations/webhook' => 'donations#webhook'
	delete 'donations/stop/:id' => 'donations#stop', as: :stop_donation
	post 'donations/confirm/:id' => 'donations#confirm', as: :confirm_donation
	post 'donations/send_reminders' => 'donations#send_reminders', as: :remind_donations
	get 'donations/search' => 'donations#search', as: :search_donations
	get 'donations/my_payments' => 'donations#my_payments', as: :my_payments
	post 'donations/update_card' => 'donations#update_card', as: :update_card
  resources :donations
  
  get 'meeting_summaries/admin' => 'meeting_summaries#admin_index', as: :admin_meeting_summaries
  resources :meeting_summaries
  
  get 'member_presentations/full_preview/:id' => 'member_presentations#full_preview', as: :full_preview_member_presentation
  get 'admin/presentations/approval_queue' => 'member_presentations#approval_queue', as: :presentations_approval_queue
  patch 'admin/presentations/approve/:id' => 'member_presentations#approve', as: :approve_presentation  
  resources :member_presentations
  
  get 'translations' => 'translations#index', as: :translations
  get 'translations/referendum/:id/original' => 'translations#review_orig_referendum', as: :review_orig_referendum
  get 'translations/referendum/preview/:id/:lang' => 'translations#preview_referendum', as: :preview_tr_referendum
  get 'translations/referendum/:id/:lang' => 'translations#translate_referendum', as: :translate_referendum
  post 'translations/referendum/:id' => 'translations#store_referendum_translation', as: :store_referendum_translation
  get 'translations/election/:id/:lang' => 'translations#translate_election', as: :translate_election
  post 'translations/election/:id' => 'translations#store_election_translation', as: :store_election_translation
	get 'translations/fundraising/:id/:lang' => 'translations#translate_fundraising', as: :translate_fundraising
  post 'translations/fundraising/:id' => 'translations#store_fundraising_translation', as: :store_fundraising_translation


  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  devise_for :users, :controllers => { registrations: 'registrations', passwords: 'passwords', confirmations: 'confirmations', :invitations => 'invitations' }, :sign_out_via => [ :get, :delete ]
	get 'change_language' => "pages#change_language", as: :change_language
	get 'membership/new' => "donations#new_membership", as: :new_membership
	get 'membership/upgrade' => 'donations#upgrade_membership', as: :upgrade_membership
	get 'membership' => "donations#edit_membership", as: :edit_membership
	post 'membership' => "donations#update_membership", as: :update_membership
	get 'optin_call' => "donations#optin_call", as: :optin_call
	post 'optin_submit' => "donations#optin_submit", as: :submit_optin
  
  get 'verifications/new' => "verifications#new", as: :new_verification
  get 'verifications/no_phone' => "verifications#no_phone_verify", as: :no_phone_verify
	post 'verifications/do_id_verify' => "verifications#do_id_verify", as: :do_id_verify
  post 'verifications/send' => "verifications#do_send_pin", as: :send_verification
  post 'verifications/check' => "verifications#check", as: :check_verification
  get 'verifications/delete_duplicate/:id' => "verifications#delete_duplicate", as: :delete_duplicate
	get 'verifications/review' => "verifications#review", as: :review_verifications
	post 'verifications/verify_member/:id' => "verifications#verify_member", as: :verify_member
	post 'verifications/reject_verification/:id' => "verifications#reject_verification", as: :reject_verification
  
  get 'vc/apply' => "vc#apply", as: :apply_to_vc
  post 'vc/apply' => "vc#submit_application", as: :submit_vc_application
	post 'vc/stop_application' => "vc#stop_application", as: :stop_vc_application
	get 'vc/confirm' => "vc#confirm_member", as: :vc_confirm
	post 'vc/confirm' => "vc#submit_confirmation", as: :submit_vc_confirmation
  get 'vc/candidates' => "vc#view_candidates", as: :view_vc_candidates
  get 'vc/view' => "vc#view", as: :view_vc
	get 'vc/vote_log' => "vc#vote_log", as: :vc_vote_log
	get 'vc/view_vote/:id' => "vc#public_view_vote", as: :public_view_vc_vote
  
  get 'admin/members' => "admin_members#index", as: :admin_members
	#get 'admin/volunteers' => "admin_members#latest_volunteers", as: :admin_volunteers
	get 'admin/members/mailchimp_export' => "admin_members#mailchimp_export", as: :mailchimp_export
  get 'admin/members/optin_export' => "admin_members#optin_export", as: :optins_export
  match 'admin/members/filter' => "admin_members#filter", as: :filter_members, via: [:get, :put]
	get 'admin/members/import' => "admin_members#import", as: :import_members
	post 'admin/members/do_import' => "admin_members#do_import", as: :do_import_members
  get 'admin/members/show/:id' => "admin_members#show", as: :admin_show_member
  get 'admin/members/edit/:id' => "admin_members#edit", as: :admin_edit_member
	put 'admin/members/confirm/:id' => "admin_members#confirm", as: :admin_confirm_member
	put 'admin/members/verify/:id' => "admin_members#verify", as: :admin_verify_member
	put 'admin/members/assign_privilege/:id' => "admin_members#assign_privilege", as: :admin_assign_privilege
  put 'admin/members/update/:id' => "admin_members#update", as: :admin_update_member
  delete 'admin/members/destroy/:id' => "admin_members#destroy", as: :admin_delete_member
  
	
	resources :stats, only: [] do
    collection do
      get 'members'
			get 'members_by_type'
			get 'members_by_other'
			get 'members_by_country'
			get 'my_signups'
			get 'signups'
      get 'signups_by_type'
      get 'signups_by_other'
			get 'signups_for_external'
			get 'top_referrers'
			post 'share_update'
    end
  end
	
	#get 'admin/stats/signups' => "admin_stats#signups", as: :admin_stats_signups
	#get 'admin/stats/signups_by_type' => "admin_stats#signups_by_type", as: :signups_by_type_stats
	
  get 'members' => 'pages#members', as: :members
  get 'newsletter' => "pages#newsletter_new", as: :new_newsletter_subscription
  post 'newsletter' => "pages#newsletter_create", as: :create_newsletter_subscription
  get 'newsletter/thanks' => "pages#newsletter_thanks", as: :thanks_newsletter_subscription
	get 'newsletter/resubscribe' => "pages#newsletter_resubscribe", as: :resubscribe_newsletter
	get 'newsletter/invitation' => "pages#email_newsletter_invitation", as: :email_newsletter_invitation
	post 'newsletter/invitation' => "pages#send_email_newsletter_invitation", as: :send_email_newsletter_invitation
	get 'pages/budget' => "pages#budget", as: :budget
	get 'pages/contact_cc' => "pages#contact_cc_form", as: :contact_cc_form
	post 'pages/contact_cc' => "pages#contact_cc", as: :contact_cc
	get 'pages/contact_diem25' => "pages#contact_diem25", as: :contact_diem25_form
	post 'pages/contact_diem25' => "pages#contact_diem25", as: :contact_diem25
	post 'pages/export_my_data' => "pages#export_my_data", as: :export_my_data
  get 'pages/share_data_with_es' => "pages#share_data_with_es", as: :share_data_with_es
	get 'policy_work' => "pages#policy_work", as: :policy_work
	get 'pages/mera25' => 'pages#mera25', as: :mera25
	post 'pages/mera25' => 'pages#create_mera25', as: :create_mera25
	get 'pages/mera25/welcome' => 'pages#mera25_welcome', as: :mera25_welcome
	
	get 'pages/join_mera25' => 'pages#join_mera25_form', as: :join_mera25_form
	post 'pages/join_mera25' => 'pages#join_mera25', as: :join_mera25
  get 'pages/team' => 'pages#team', as: :team
  get 'pages/chat' => 'pages#chat', as: :chat
  get 'pages/goodies' => 'pages#goodies', as: :goodies
  get 'pages/welcome' => 'pages#index', as: :dashboard
	
	get 'discourse/sso' => 'discourse_sso#sso'
	
	post 'embed/send_contact' => 'embed#send_contact', as: :send_contact
	get 'embed(/:action)', controller: 'embed'
	
	match '*not_found', via: [:get, :post], to: 'pages#error_404'
end  
  
  # You can have the root of your site routed with "root"
  root 'pages#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
