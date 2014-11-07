# -*- encoding : utf-8 -*-
MQ_CONFIG = YAML.load_file("#{Rails.root}/config/mq_config.yml")[Rails.env]

# In tests, then MQ uri will be overridden by the environment variable 'MQ_URI'
if Rails.env.upcase == 'TEST' && !ENV['MQ_URI'].blank?
  MQ_CONFIG['mq_uri'] = ENV['MQ_URI']
  puts "Setting test MQ settings from environment variables: #{MQ_CONFIG.inspect}"
end