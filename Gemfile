source 'http://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', "5.1"

# Use sqlite3 as the database for Active Record
# gem 'sqlite3'

gem 'pg', '~> 0.18'
gem 'bulk_insert'

gem 'aws-sdk'

gem 'translateable'
gem 'nested_form_fields'

gem 'figaro'

gem 'chartkick'
gem 'groupdate'

gem 'nokogiri'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'coffee-script-source', '1.8.0'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', :platforms => :ruby

  gem 'uglifier'
end

group :development do 
  gem 'derailed'
	gem 'sys-proctable', platforms: [:mingw, :mswin]
end

group :test, :development do
  gem "factory_bot_rails"
  gem 'rspec-rails'
  gem 'cucumber-rails', :require => false
  # database_cleaner is not required, but highly recommended
  gem 'database_cleaner'
	gem 'poltergeist'
  #gem 'selenium-webdriver'
  # gem 'byebug'
end

gem 'puma'
group :production do
  gem 'rails_12factor'
	gem 'scout_apm'
end

# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-ui-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
#gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
#gem 'jbuilder'
# bundle exec rake doc:rails generates the API under doc/api.
#gem 'sdoc',          group: :doc

gem 'devise'
gem 'gibbon'
gem 'activeadmin', '1.4.3'
  gem 'inherited_resources', '1.9.0'
  gem 'responders', '2.4.0'

#gem 'will_paginate'

gem 'tinymce-rails'
gem 'country_select', '~> 3.1'
gem 'rails-i18n'
gem 'http_accept_language'

# Use ActiveModel has_secure_password
# gem 'bcrypt'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Recaptcha against spammers
gem "recaptcha", require: "recaptcha/rails"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin]

# Adding support to generate Invitations with Devise
gem 'devise_invitable', '~> 1.7.0'

ruby "2.3.3"
