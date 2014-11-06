require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Load the local ldap configuration
def recursive_symbolize_keys!(hash)
  hash.symbolize_keys!
  hash.values.select { |v| v.is_a? Hash }.each { |h| recursive_symbolize_keys!(h) }
end

# Load config details in - will crash out if config not present
CONFIG = YAML.load(File.read(File.expand_path('../application.local.yml', __FILE__)))
CONFIG.merge! CONFIG.fetch(Rails.env, {})
recursive_symbolize_keys!(CONFIG)



module Hel
  class Application < Rails::Application

    config.autoload_paths += Dir[Rails.root.join('app', 'models', 'datastreams', '{**}')]
    config.autoload_paths += Dir[Rails.root.join('app', 'helpers', 'constants.rb')]
    config.autoload_paths += Dir[Rails.root.join('app', 'export', '{**}')]
    config.autoload_paths += Dir[Rails.root.join('lib', '{**}')]

    config.generators do |g|
      g.test_framework :rspec, :spec => true
    end


    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
  end
end
