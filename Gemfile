source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '>= 4.1.6'

# Using this branch until bugfix makes it into hydra / AF master
# See https://github.com/projecthydra/active_fedora/pull/781
gem 'active-fedora', '>= 9.1.2'
# Use sqlite3 as the database for Active Record
gem 'sqlite3'
gem 'uuid'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.3'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer'

gem 'rouge' # syntax highlighting gem for display of XML data

# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-validation-rails'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0',          group: :doc
gem 'hydra', '>= 9.1.0.rc1'
gem 'hydra-file_characterization', '~> 0.3.1'
gem 'simple_form'
gem 'lograge'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data'
# Preservation
gem 'bunny', '>= 2.1.0'
gem 'amq-protocol', '>= 2.0.0'

gem 'isbn_validation'
gem 'edtf'

gem 'devise'
gem 'devise-guests', "~> 0.3"
gem 'devise_ldap_authenticatable'


gem 'ohm'
gem 'httparty'

gem 'resque'
gem 'resque-scheduler'
gem 'rdf-vocab', '>= 0.6.0'
gem 'rsolr'
gem 'jquery-ui-rails'

group :development, :test do
  gem 'simplecov'
  gem 'rspec-rails'
  gem 'jettywrapper', '~> 2.0.0'
  gem 'thin'
  gem 'linkeddata'
  gem 'cucumber-rails', require: false
  gem 'launchy'
end


group :development do
  gem 'byebug'
  gem 'better_errors'
  gem 'binding_of_caller'
#  gem 'rack-mini-profiler'
# gem 'flamegraph'
# gem 'stackprof'
end

group :test do
  gem 'fakeredis'
  gem 'factory_girl_rails'
end

#logging start
gem 'log4r', '1.1.10'
gem 'quiet_assets'
#logging end

#gem 'rsolr'
