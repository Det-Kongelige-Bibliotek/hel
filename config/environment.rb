# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      puts "Forked"
      # We’re in a smart spawning mode
      # Now is a good time to connect to RabbitMQ
    end
  end
else
  if Rails.env.upcase != 'TEST'
    puts "not PhusionPassenger"
  end
  # We're in direct spawning mode. We don't need to do anything.
end
