# -*- coding: utf-8 -*-
require 'fakeredis'
# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'

# calulate code coverage and generates a 'coverage/' directory
require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
end

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
# ActiveRecord::Migration.maintain_test_schema!


RSpec.configure do |config|
  config.filter_run_excluding broken: true
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.include FactoryGirl::Syntax::Methods
  config.include Devise::TestHelpers, :type => :controller

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  # config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  config.before :all do
    #ActiveRecord::Base.subclasses.each(&:delete_all)
    # ActiveFedora::Base.subclasses.each(&:delete_all)
    a = Administration::Activity.create(
        "activity"=>"Trygforlæg",
        "collection"=>["billed"],
        "availability"=>"0",
        "embargo"=>"0",
        "access_condition"=>"efter aftale",
        "preservation_collection"=>"storage",
        "copyright"=>"Attribution-ShareAlike CC BY-SA",
        "activity_permissions"=>{"instance"=>{"group"=>{"discover"=>["Chronos-Alle"], "read"=>["Chronos-NSA"], "edit"=>["Chronos-Pligtaflevering","Chronos-Admin"]}}, "file"=>{"group"=>{"discover"=>["Chronos-NSA"], "read"=>["Chronos-Pligtaflevering"], "edit"=>["Chronos-Admin"]}}})
    @default_activity_id = a.id
  end

  def login_admin
    @admin = FactoryGirl.create(:admin)
    controller.stub(:current_user).and_return(@admin)
  end

end
